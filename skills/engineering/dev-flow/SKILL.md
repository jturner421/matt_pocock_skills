---
name: dev-flow
description: "Orchestrate one piece of work from first discussion to released tickets: prime from haft, entry, the bound decision, build spec and tickets, and the release decision. Ends at the launch command handover."
disable-model-invocation: true
---

# dev-flow

Take one piece of work from discussion to released tickets. This skill owns the conversation stages only: prime, entry, the bound decision, the build spec and tickets, and the release decision. Everything after release belongs to the machinery (sandcastle, GitLab, and the GitLab Jira integration): implementation, review, merge request, merge, closure. Never drive those from here.

Design rationale, the end-to-end flow, and which artifact lives in haft and which in the skills are in [DESIGN.md](./DESIGN.md); read it when a boundary question comes up, not routinely.

## 0. Prime

In a haft-governed repo (`.haft/` exists), run `haft check` and read it with the user: claims ready for verification, drift, unassessed decisions. Call the Skill tool with "h-verify" for each claim ready for verification before any new work; the user may defer a claim by naming it. Prior decisions frame everything below.

Read `docs/agents/issue-tracker.md`: it is the single source of truth for this repo's ticket mechanics (auth bootstrap, creation commands, labels, state model, wayfinding operations). If it does not exist, stop and tell the user to run `/setup-matt-pocock-skills`.

## 1. Entry

Four doors. Present them, let the user pick:

- **wayfinder** (`/wayfinder`): the effort is bigger than one session and the route is unclear. Produces a map Epic and decision tickets, worked one per session.
- **grill-with-docs** (`/grill-with-docs`): the problem fits in a session and there is a plan or design to sharpen. Produces a spec-ready understanding and the material a decision record needs: options, trade-offs, the weakest link.
- **Resume a map**: wayfinder work mode against an existing map Epic; find the frontier per the tracker doc's Wayfinding operations.
- **Direct to ticket**: small, well-understood work; skip to step 3, through step 2 when a choice was made.

Two branches inside the first three doors:

- **A question needs a runnable answer** (state, business logic, a UI you have to see). Tell the user to run `/handoff` with the question, open a fresh session on that file, answer it there with the `prototype` skill, and `/handoff` back. The returned file is a primary source for the rest of this step.
- **A map item is deferred, not resolved.** Call the Skill tool with "h-frame" to record it as a ProblemCard carrying the ticket key, then close the ticket with a comment naming the card. A ProblemCard that becomes current later enters through a door like any other work.

## 2. Bind the decision

No bound DecisionRecord, no tickets. Record in haft before any ticket exists:

- **Mode is mechanical.** Standard when all three hold: hard to reverse, surprising without context, the result of a real trade-off. Tactical otherwise. Direct-to-ticket work with no choice in it records nothing.
- **The user binds.** Call the Skill tool with "h-decide" to prepare the brief from the material the entry step produced; the user's words bind it. haft rejects model-supplied authority, so never bind on the user's behalf.
- **Notes hold findings.** Call the Skill tool with "h-note" for facts and rationale a later session must find. A note never carries the decision.
- **`docs/adr/` is frozen history.** When the decision touches an area an ADR covers, list that ADR's path in `affected_files`, state extends or supersedes in the rationale, and on supersede add `Status: superseded by <dec-id>` to the ADR.

## 3. Build spec and tickets

For wayfinder output and plan-shaped work, run `/to-spec` first: it collapses the thread into a build spec, published as the Epic's description, not as a ticket and with no `ready-for-agent` label. Then slice. For everything else, slice directly.

One slicing rule on every path: vertical slices; `to-tickets` owns the rules and the quiz-the-user step. Three shapes:

- **Multi-slice work** → `/to-tickets`: slice, quiz on granularity and blocking edges, publish per the tracker doc.
- **Plan-shaped work** → `/to-spec`, then the same slicing, published as an Epic with Story children.
- **DecisionRecord-driven single ticket** → one Story created from the bound decision.

Every build spec and every ticket names the DecisionRecord ids it rests on: that is how the worker finds the decision it must not drift from.

Publish per the tracker doc: `[SLUG]` summary prefix, Story/Task/Bug typing, epic links, "is blocked by" links, `ready-for-agent` on implementation tickets, and **no repository slug label**. Unlabeled tickets are visible and refinable in Jira, and invisible to the agent.

## 4. The release decision: human, explicit

Present the decision point: which tickets go to the agent, and how. You propose; the user decides. **Releasing a ticket is applying the repository slug label** (the label-add command in the tracker doc). Apply it only to tickets the user names, at the moment of actual release, never speculatively. Before applying it, confirm each record the ticket cites (DecisionRecord, note) is on the branch the agent builds from (`git log origin/<base> -- <path>`); an unpushed record leaves the worker with the ticket text alone. Then hand over the launch command for the chosen lane:

- **Batch**: `mise run sandcastle` works the labeled, unblocked frontier, one branch and one MR per ticket; blocked tickets wait, so run again after MRs merge to pick up the newly unblocked wave.
- **Single ticket**: `mise run sandcastle WD-123`.
- Either lane takes `--codex-review=always|never` to force or skip the Codex second review for the run; the default gate is in DESIGN.md §6. The run checks the Codex login and the sandbox image before it starts.
- **In-session**: transition the ticket to In Progress, then `/implement` for the work, `/gl:commit` to commit, `/gl:create_mr` for the MR.

The skill ends here: label applied, command handed over. Tickets close when their MR merges into develop (GitLab Jira integration); nobody closes code-bearing tickets by hand. Verification of the decision's predictions returns at the next session's step 0.

## Context hygiene

Keep steps 1 to 3 in one unbroken window: the grilling, the decision, the spec, and the tickets build on the same thinking. If the window fills before tickets exist, decide at the phase boundary with the ordered tree in [`../ask-matt/PHASE-BOUNDARIES.md`](../ask-matt/PHASE-BOUNDARIES.md); mid-phase, continue or split the remainder into subagents.
