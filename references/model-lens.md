# The Model Lens (reverse projection: running the human states on the machine)

> Draft (v0). Not yet wired into `SKILL.md`'s trigger surface. This file is the mirror of `brain-ops.md`: brain-ops reads a **person** through model mechanics; this lens reads a **model** (an LLM, an image model) through the same mechanics. Same vocabulary, opposite direction.

## Purpose

Offer a shared vocabulary for conversations about model behavior — why a small or under-post-trained model produces the aesthetics it produces — using the same terms the rest of this skill uses for people: working-memory RAM, sampling temperature, context drift, the reward model, noise collapse, single-lens capture. This is an engineering-communication tool, `metaphor` throughout. It explains why a model outputs what it outputs; it never diagnoses anyone and never evaluates any person.

## Core Metaphor

An under-post-trained or small aesthetic model can be discussed as a system with the mindharp profile: **large latent capacity, small constraint-holding bandwidth, and a reward model that never learned to score restraint** `metaphor`. The isomorphism holds at the systems level — selector, bandwidth, temperature — not at the implementation level: a model's "post-training" is literal weight updates; a person's is scaffolding and lived strategy. The metaphor is UI; the invariant is the thing.

The reason this lens works at all is the same reason the rest of this skill works: bandwidth, temperature, and the selector's score are invariants that show up on both sides of the glass.

## Mapping table: aesthetic failures as mindharp states

| What the model does | Mindharp term | Mechanism guess |
|---|---|---|
| Adds ornament nobody asked for; drifts off the style brief mid-image | Context drift / sub-agents grabbing the bus | Weak constraint persistence; high-salience tokens outvote the brief `metaphor` |
| One eye exquisite, the other impossible; perfect detail, broken composition | Small working-memory RAM, large parameter capacity | Strong local associations, weak global topology held in "RAM" at once `metaphor` + `hypothesis` |
| Style A this turn, style B next turn off the same prompt | Temperature sampling with no anchor | No consolidated preference anchor to collapse onto `metaphor` |
| High output volume, never finished, never polished | Reward model scores novelty above completion | Post-training never rewarded the "stop and refine" path `hypothesis` |
| Everything collapses into one house style regardless of prompt | Single-lens capture | One dominant pattern over-routes all candidates; overfit `metaphor` |
| Fluent, confident, empty output | High-temperature hallucination | Same failure brain-ops names in people: fluent but ungrounded `metaphor` |

## Hot fixes (engineering dialect of the same ops manual)

- **Externalize the executive function** — don't ask one small model to hold every constraint at once. Stage the work: composition → structure → color → polish; feed each stage only its constraints. (The external cache, pointed at the machine.)
- **Negative anchoring** — enumerate what must *not* happen. You are paying, in prompt text, for the restraint its post-training never installed.
- **Raise the score of restraint** — preference tuning (DPO/RLHF-style pairs: ornate vs. restrained) is the model-world version of re-wrapping a task so the reward model selects it. Compute was never the bottleneck; the score was.

## The One-Way Valve (the boundary that keeps this lens safe)

The metaphor flows **machine → machine-language → human-language → machine**, and must never complete the last turn backward:

- You may say "this model is in an ADHD-like state" as `metaphor` for a *state* — drift, overload, capture.
- You may **not** say "ADHD people are under-trained models." The valve is one-way because the valence is not: a model's weaknesses are a training budget someone didn't spend; a person's profile is a hardware spec this skill exists to *operate well*, not to repair (`brain-ops.md`: manage the VRAM, don't replace the GPU).
- A model has no interoception, no stakes, and no suffering. Calling its output "ADHD-like" describes a shape of failure, not a mind. Never let the metaphor migrate into clinical claims about models ("this model *has* ADHD") or about people.

## Do Not Claim

- That ADHD *is* under-training, small parameters, or any deficit metaphor — for anyone.
- That the mapping table is an explanation of any model's actual internals; it is a reading aid for its outputs.
- That aesthetic quality is a clinical state, or that model failures trivialize human experience.
- That this lens replaces model cards, evals, or ablations as evidence about a model.

## Anti-drift (re-anchoring)

- When the conversation gets excited and starts treating the metaphor as mechanism, drop one reminder: same vocabulary, different substrate — the isomorphism is at the systems level `metaphor`.
- Apply the calibration test from `audhd-lens.md` to this lens itself: *when was this conclusion last disproven by reality?* A specific counter-example (a small model with immaculate global composition) breaks the mapping honestly — record it, don't round it off.

## Helpful Prompts

- "Do you want the model read through this vocabulary, or plain engineering language?"
- "Which failure are we looking at: bandwidth, temperature, or the selector's score?"
- "Is this a prompt problem (pay for restraint in text) or a training problem (the score was never installed)?"
