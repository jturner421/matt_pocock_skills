---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If the work is a Jira ticket, transition it to In Progress before starting (commands in the repo's `docs/agents/issue-tracker.md`).

Before writing code, make the unknowns explicit: note the parts of the spec most likely to change (data models, interfaces, UX flows) and anything it leaves open. Resolve open questions by reading references or asking the user — not by guessing silently.

If a CODING_STANDARDS.md exists at the project root, read it before writing any code and follow it throughout — don't defer standards to review time.

If the spec splits into independent slices touching disjoint files, delegate each slice to a subagent (pass `model: "sonnet"`) and act as overseer: give each a self-contained brief and review each diff at the slice boundary — a drift caught at a boundary costs one slice; caught at the end it costs the run. Parallelism must earn its coordination cost; sequential work in one context is the default. If you are yourself the cheaper worker in a monitored loop, invert it: have a more capable agent refute your plan before you start and adversarially review your diff before you commit — never be the sole verifier of your own work.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Keep a short running note of deviations from the spec as they happen — when an edge case forces a choice the spec doesn't cover, pick the conservative option and log it rather than stopping. Fold the note into the commit message and hand it to review.

Once done, use /code-review to review the work.

Commit your work to the current branch.

When the work is a Jira ticket: commit via `/gl:commit` after code-review approval and, when the work warrants a merge request, open it with `/gl:create_mr`. The ticket closes when the MR merges — never close it by hand.
