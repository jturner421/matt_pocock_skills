# Subagent orchestration and model tiers

Canonical reference for every skill in this fork that spawns subagents. Skills
link here instead of repeating model-selection rules.

## Model roles

| Model | Role in this fork |
|-------|-------------------|
| Haiku | High-volume mechanical steps: file inventory, log scanning, formatting sweeps. |
| Sonnet (`model: "sonnet"`, currently Sonnet 5.5) | Default worker. Implementation, test-writing, focused research reads, per-file review passes. |
| Opus (`model: "opus"`, currently Opus 5.5) | Default orchestrator for well-specified work. Plans, decomposes, dispatches Sonnet workers, integrates results. |
| Fable (`model: "fable"`, currently Fable 5.1) | Advisor and escalation tier. Reviews plans and finished work at checkpoints, resolves ambiguity, arbitrates disagreement. Takes the orchestrator or judging seat when unknown density or judgment density is high. |

## The advisor pattern (default shape)

Worker models execute; a more capable model coaches and evaluates. Anthropic's
published result: Sonnet workers with a Fable advisor land within 10% of
Fable-alone quality at 63% of the price. Applied here:

1. Orchestrator (Opus) decomposes the task and dispatches Sonnet workers.
2. Workers return structured results, including a **Deviations** list: any
   point where they chose a conservative option over asking.
3. At defined checkpoints (plan approved, phase complete, tests green), the
   advisor (Fable, or Opus when stakes are low) reviews output against the
   spec and either accepts, redirects the worker, or escalates to the user.

Checkpoints are where quality is recovered cheaply.

The within-10%-at-63% figure was published against Fable 5 and has not been
re-measured on Fable 5.1.

## When Fable orchestrates instead of Opus

Route the *orchestrator* seat to Fable when unknown density is high: quality
is then bottlenecked by clarifying unknowns, which is Fable's edge:

- Novel domain or unfamiliar codebase; no similar prior art to point at.
- The spec is ambiguous and answers would change the architecture.
- Design/architecture decisions dominate (improve-codebase-architecture,
  greenfield to-spec work, hard diagnosis with rival hypotheses).
- An earlier Opus-orchestrated run drifted from the goal or stalled.

Keep Opus as orchestrator when the work is well-specified: tickets with
acceptance criteria, mechanical migrations, review of a bounded diff.

## Current-model notes

On a Claude subscription or the Anthropic API, the `opus` and `sonnet` aliases
resolve to Opus 5.5 and Sonnet 5.5, so skills pass aliases and need no pinning
(the Agent tool accepts only aliases). Other providers resolve `sonnet` to an
older model; pin there with `ANTHROPIC_DEFAULT_SONNET_MODEL` /
`ANTHROPIC_DEFAULT_OPUS_MODEL`, not in a skill.

From Anthropic's Opus 5.5 and Sonnet 5.5 prompting guides:

- Effort is the thinking control; prompt lines asking for more or less
  thinking are less reliable. Opus 5.5 at `medium` (its default) matches
  Opus 5 at `high`, so run orchestrator sessions at `medium` and reserve
  `xhigh`/`max` for work where a gain was measured.
- Sonnet 5.5 workers at `low`/`medium` effort tend to check in before the work
  is done, and at every effort add tests, docs and files nobody asked for; at
  `xhigh`/`max` they launch their own reviewer sub-agents. Coding briefs
  (implement, implement-spec) therefore carry a carry-through-and-scope
  clause and a real-check verification rule.
- Sonnet 5.5 answers from training knowledge when a search would catch a
  changed detail; research tells its worker to check such specifics.
- Opus 5.5 sustains long unattended runs with parallel sub-agents, but ends
  turns with progress reports; implement-spec names the stops it should not
  make.

From Fable 5.1's guide:

- Parallel sub-agents are dependable, and the orchestrator should keep working
  while they run rather than block on each one. The skills no longer treat
  sequential single-context work as the default.
- At low effort, Fable 5.1 is often competitive with Opus and Sonnet on cost
  per task while scoring higher. The Agent tool exposes a model but no effort
  setting, so a low-effort Fable worker is not yet expressible from a skill.
  Treat it as an eval to run before moving any worker seat off Sonnet.

## Loop architecture (implementation with oversight)

For ticket/spec implementation, run a monitored loop rather than one long
worker context:

```
advisor (Fable/Opus)                 worker (Sonnet)
  approve plan  ──────────────────▶  implement slice (tdd)
  review slice ◀──────────────────   tests + deviations report
  accept / redirect ──────────────▶  next slice ...
  final review: full suite, spec conformance, code-review skill
```

Fresh worker context per slice or phase; the accumulated artifacts (spec,
plan, deviations log) carry state between contexts, not the transcript.

## Workflow-tool patterns worth reaching for

Use the Workflow tool (or explicit Agent fan-out) when the shape fits;
otherwise a single agent is cheaper and simpler; most ordinary coding tasks
do not need a panel of reviewers.

- **Fan-out and synthesize**: many small independent units (per-file review,
  migration sites, research sources). Sonnet workers, Opus synthesis.
- **Adversarial verification**: independent verifiers prompted to refute a
  finding before it is reported. Counters self-preferential bias. Verifiers
  can be Sonnet; the arbiter of disagreement should be Opus/Fable.
- **Tournament / judge panel**: several distinct attempts scored by judges.
  Reserve for wide solution spaces (design, architecture), not routine fixes.
- **Loop until done**: spawn workers until a stopping condition, not a fixed
  count. Guard with an explicit token budget.

Known failure modes these exist to counter: agentic laziness (premature
"done"), self-preferential bias, and goal drift across long contexts. The
advisor checkpoint is the general antidote to all three.

## Orchestrator seat per engineering skill

Which model should be *running the session* when each skill fires. The
consumer of this table is the human (or dispatching agent) choosing a session
model *before* invoking the skill; the skills themselves don't read it; each
carries its own inline worker-model guidance. Fable where clarifying unknowns
or judging is the product, Opus where the work is well-specified, Sonnet where
the skill is a thin worker discipline.

| Skill | Seat | Why |
|-------|------|-----|
| wayfinder | **Fable** | Charting fog and naming unknowns is the entire job, the strongest Fable case in the repo. |
| improve-codebase-architecture | **Fable** | Taste-based architectural judgment; wide solution space; drives the design-it-twice judging seat. |
| grill-with-docs | **Fable** | Question quality is the product; answers reshape the domain model. |
| codebase-design (design-it-twice) | **Fable** | Judging seat over Opus-generated candidates: judgment density, not unknown density. |
| diagnosing-bugs | Opus, **Fable when stuck** | Routine repro-and-fix is Opus work; escalate the seat when the bug resists reproduction or hypotheses keep dying. |
| to-spec | Opus, Fable if ambiguity is high | Synthesis of an already-had conversation is Opus work; Fable when the spec will lock in architecture. |
| to-tickets | Opus | Decomposition of a settled spec; slicing is judgment but bounded. |
| implement | Opus orchestrating Sonnet workers | Well-specified by construction (spec/tickets exist). Fable appears as checkpoint advisor. In an autonomous loop (e.g. sandcastle), a Sonnet worker may hold the seat itself; the skill then requires it to arrange capable-model plan refutation and diff review. |
| implement-spec | Opus orchestrating Sonnet workers | Same shape as implement at spec scale: the orchestrator walks the ticket frontier and dispatches tdd-driven implementer and merger subagents. |
| code-review | Opus | Bounded diff against explicit rubrics; Sonnet sub-reviewers. |
| pr | Sonnet/Opus | Fills a fixed template from a finished diff; Opus when the merge-danger call (door, blast radius) needs real judgment. |
| retro | Opus | Reads a whole session's sources and ranks environment fixes by severity; bounded judgment over a known transcript. |
| triage | Opus | State-machine discipline; claim-verification can fan out to Sonnet. |
| domain-modeling | Inherits caller's seat | A discipline invoked inside other skills, not a session of its own. |
| tdd | Inherits worker's seat | The implementation loop's discipline, typically Sonnet under advisor oversight. |
| prototype | Sonnet/Opus | Throwaway speed over polish; escalate only if the design question itself is the hard part. |
| research | Any (worker is Sonnet) | The orchestrator only dispatches and later reads the note. |
| ask-matt, setup-matt-pocock-skills | Any | Routing and one-time configuration. |
