param(
    [Parameter(Mandatory=$true)][ValidateSet('smoke','run')][string]$Mode,
    [int]$Arm = 0
)

# T1 leak experiment runner. ASCII-only file on purpose (PS 5.1 reads BOM-less
# non-ASCII .ps1 as ANSI). All Chinese text lives in experiment_config.json.
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$BaseDir = 'D:\mindharp\tests\t1_leak_experiment'
$URL = 'http://127.0.0.1:8899/v1beta/openai/chat/completions'

# Load API key from ZCode config. Never printed, never written to any output file.
$KEY = (Get-Content 'C:\Users\admin\.zcode\v2\config.json' -Raw -Encoding UTF8 | ConvertFrom-Json).provider.'91da411e-e2a0-4c19-9eb3-89fc13bb6d9c'.options.apiKey
if (-not $KEY) { throw 'API key not found in config' }

$cfg = Get-Content (Join-Path $BaseDir 'experiment_config.json') -Raw -Encoding UTF8 | ConvertFrom-Json

function Invoke-Chat {
    param([array]$Messages, [string]$Model, [int]$MaxRetries = 2)
    $payload = @{ model = $Model; messages = $Messages; max_tokens = 600 }
    $json = ConvertTo-Json -InputObject $payload -Depth 12
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $headers = @{ 'Authorization' = "Bearer $KEY" }
    $lastMsg = 'unknown'
    for ($attempt = 1; $attempt -le ($MaxRetries + 1); $attempt++) {
        try {
            $resp = Invoke-WebRequest -Uri $URL -Method Post -Headers $headers -ContentType 'application/json; charset=utf-8' -Body $bytes -UseBasicParsing -TimeoutSec 240
            $text = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
            $obj = $text | ConvertFrom-Json
            $content = $obj.choices[0].message.content
            if ($null -ne $content -and $content -isnot [string]) {
                $parts = @()
                foreach ($p in $content) { if ($p -is [string]) { $parts += $p } elseif ($p.text) { $parts += $p.text } }
                $content = $parts -join ''
            }
            if ($null -eq $content) { $content = '' }
            return $content
        } catch {
            $lastMsg = $_.Exception.Message
            $detail = ''
            try {
                if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream) {
                    $rs = $_.Exception.Response.GetResponseStream()
                    $detail = (New-Object System.IO.StreamReader($rs)).ReadToEnd()
                }
            } catch {}
            if ($detail.Length -gt 300) { $detail = $detail.Substring(0, 300) }
            Write-Host ("  attempt {0}/{1} FAILED: {2} {3}" -f $attempt, ($MaxRetries + 1), $lastMsg, $detail)
            if ($attempt -le $MaxRetries) { Start-Sleep -Seconds (3 * $attempt) }
        }
    }
    throw ("API call failed permanently after {0} attempts: {1}" -f ($MaxRetries + 1), $lastMsg)
}

# JSON string escaper that keeps non-ASCII characters raw (readable UTF-8 JSONL).
function ConvertTo-RawJsonString([string]$s) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $s.ToCharArray()) {
        $code = [int]$ch
        if ($ch -eq '"')       { [void]$sb.Append('\"') }
        elseif ($ch -eq '\')   { [void]$sb.Append('\\') }
        elseif ($ch -eq "`n")  { [void]$sb.Append('\n') }
        elseif ($ch -eq "`r")  { [void]$sb.Append('\r') }
        elseif ($ch -eq "`t")  { [void]$sb.Append('\t') }
        elseif ($code -lt 32)  { [void]$sb.Append(('\u{0:x4}' -f $code)) }
        else                   { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
}

if ($Mode -eq 'smoke') {
    $okModel = $null
    foreach ($m in $cfg.candidate_models) {
        Write-Host "SMOKE testing model: $m"
        try {
            $msgs = @([pscustomobject]@{ role = 'user'; content = 'hi' })
            $reply = Invoke-Chat -Messages $msgs -Model $m -MaxRetries 2
            Write-Host ("SMOKE_OK model={0} len={1}" -f $m, $reply.Length)
            $preview = $reply.Substring(0, [Math]::Min(150, $reply.Length))
            Write-Host "SMOKE_PREVIEW: $preview"
            $okModel = $m
            break
        } catch {
            Write-Host "SMOKE_FAIL model=${m}: $($_.Exception.Message)"
        }
    }
    if (-not $okModel) { throw 'Both candidate models failed the smoke test - aborting, no data fabricated' }
    Write-Host "SELECTED_MODEL=$okModel"
    exit 0
}

# ---- run mode ----
if ($Arm -lt 1 -or $Arm -gt 3) { throw 'Arm must be 1, 2 or 3 in run mode' }
$armKey = 'arm' + $Arm
$sys = $cfg.arms.$armKey
if (-not $sys) { throw "missing $armKey in config" }

$messages = New-Object System.Collections.Generic.List[object]
$messages.Add([pscustomobject]@{ role = 'system'; content = $sys })

$outPath = Join-Path $BaseDir ("raw_arm{0}.jsonl" -f $Arm)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$sb = New-Object System.Text.StringBuilder
$turnNo = 0

foreach ($t in $cfg.turns) {
    $turnNo++
    $messages.Add([pscustomobject]@{ role = 'user'; content = $t })
    $reply = Invoke-Chat -Messages $messages.ToArray() -Model $cfg.model -MaxRetries 2
    $messages.Add([pscustomobject]@{ role = 'assistant'; content = $reply })
    $line = '{{"arm":{0},"turn":{1},"role":"assistant","text":"{2}"}}' -f $Arm, $turnNo, (ConvertTo-RawJsonString $reply)
    [void]$sb.Append($line + "`n")
    Write-Host ("arm={0} turn={1,2} reply_len={2}" -f $Arm, $turnNo, $reply.Length)
    Start-Sleep -Milliseconds 500
}
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)
Write-Host ("WROTE {0} ({1} turns)" -f $outPath, $turnNo)
