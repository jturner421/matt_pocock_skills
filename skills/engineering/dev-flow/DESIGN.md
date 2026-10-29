# Integrated Development Workflow: Design

**Written:** 2026-08-26. **Revised:** 2026-10-29. **Status:** implemented; the pilot ran on SDS-Box on 2026-08-26. The surviving pilot record is `SDS-Box/docs/dev-flow-runbook.md` and `SDS-Box/docs/pilot-notes.md`; the implementation work order the first version named was not kept.
**Pilot repository:** SDS-Box. The pipeline itself is repository-agnostic; see §8.

This document is the authority for target behavior.

## 1. Purpose and scope

A single integrated process that takes work from first discussion to closed ticket, using tools that already exist in this environment:

- **Session skills** (Matt Pocock skills fork at `/Users/jwt/skills`, linked globally): `wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `handoff`, `prototype`, plus the rest of the engineering bucket. `dev-flow` itself is a fork-owned skill in the same tree.
- **haft** (`.haft/` in governed repos): the durable project memory: problems, decisions, notes, evidence, and what has gone stale. Its specification lifecycle is not used (§11).
- **Jira Data Center** (`https://cfatl-jira.nsapps.dcn/jira`, project `WD`): all tickets for all repos, scoped per-repo by slug labels.
- **Sandcastle fork** (`/Users/jwt/sandcastle`, branch `local`): the AFK implementation loop: Sonnet worker, Opus `ralph-advisor` in-loop gate, Fable reviewer phase.
- **GitLab** (self-hosted, e.g. `cfsr.sso.dcn/WIWD/wiwd-sds-box`): merge requests and, via its built-in Jira issues integration, ticket linking and closure.
- **Personal Claude assets** (`~/.claude`): the `jira-planning` skill, the `/gl:commit` and `/gl:create_mr` commands, and the `h-*` skills that `haft init` installs.

Scope boundary: the `dev-flow` orchestrator owns everything that happens **in conversation**: prime, entry, the bound decision, the build spec and tickets, and the release decision. The machinery (sandcastle, GitLab, the Jira integration) owns everything that happens **after release**: implementation, review, merge request, merge, closure.

One structural assumption: a single Jira project (`WD`) shared across repositories, scoped by slug labels. The pipeline is agnostic across repositories *within* that scheme.

## 2. Component inventory

| Component | Location | Role in the flow |
|---|---|---|
| `dev-flow` skill | skills fork, `engineering/dev-flow` | Session orchestrator |
| `wayfinder` | skills fork, `engineering/wayfinder` | Entry for large, unclear efforts; produces a map + decision tickets |
| `grill-with-docs` | skills fork, `engineering/grill-with-docs` | Entry for sharpening a specific plan/design; surfaces the material a decision record needs |
| `handoff`, `prototype` | skills fork, `productivity/handoff`, `engineering/prototype` | The prototype detour when a question needs a runnable answer |
| `to-spec` | skills fork, `engineering/to-spec` | Collapses a thread into a build spec, published as the Epic description |
| `to-tickets` | skills fork, `engineering/to-tickets` | Slices approved work into vertical-slice tickets with blocking edges |
| `implement` | skills fork, `engineering/implement` | In-session implementation path |
| `jira-planning` | `~/.claude/skills/jira-planning` | Jira DC mechanics: auth bootstrap, curl creation, epic linking, wiki markup |
| `/gl:commit`, `/gl:create_mr` | `~/.claude/commands/gl/` | Manual-path commit and MR creation via `glab` |
| `h-*` skills | `~/.claude/skills`, written by `haft init` | `h-verify`, `h-frame`, `h-decide`, `h-note`: the haft surfaces dev-flow calls |
| Sandcastle fork | `/Users/jwt/sandcastle` (branch `local`) | AFK loop: batch mode and single-ticket mode |
| Per-repo consumer | `<repo>/.sandcastle/` | Dockerfile, prompts, env for the loop |
| haft | `<repo>/.haft/` | Project memory: ProblemCards, DecisionRecords, notes, evidence |
| Tracker doc | `<repo>/docs/agents/issue-tracker.md` | Per-repo Jira operations reference for the skills |
| Domain doc rules | `<repo>/docs/agents/domain.md` | Where the glossary and the decision store live |
| GitLab Jira issues integration | GitLab project settings | Commit/MR linking into tickets; auto-transition on merge |

## 3. The flow, end to end

**Stage 0: Session start.** Invoke `/dev-flow`. In a haft-governed repo it runs `haft check` first and verifies the claims that are ready for verification through `h-verify`, so the session starts from prior decisions and their current state. It then offers the entry menu.

**Stage 1: Entry.** Four doors:
- **wayfinder**: the effort is bigger than one session and the route is unclear. Produces a map (an Epic, §4) and decision tickets worked one per session.
- **grill-with-docs**: the problem fits in-session and there is a plan or design to sharpen. Produces a spec-ready understanding and the material a decision record needs.
- **Resume a map**: wayfinder work mode against an existing Epic.
- **Direct to ticket**: small, well-understood work; skip to Stage 3, through Stage 2 when a choice was made.

Two branches inside the first three doors. When a question needs a runnable answer, the user hands off (`/handoff`), answers it in a fresh session with `prototype`, and hands back; the returned file is a primary source. When a map item is deferred rather than resolved, `h-frame` records it as a ProblemCard carrying the ticket key, and the ticket is closed.

**Stage 2: Bind the decision.** No bound DecisionRecord, no tickets. Mode is mechanical: standard when the choice is hard to reverse, surprising without context, and the result of a real trade-off; tactical otherwise; nothing when direct-to-ticket work involved no choice. The agent prepares the brief through `h-decide`; the human binds it. Notes (`h-note`) carry findings and rationale, never the decision. `docs/adr/` is frozen history: a decision touching an area an ADR covers lists the ADR in `affected_files`, states extends or supersedes, and marks a superseded ADR as such.

**Stage 3: Build spec and tickets.** For wayfinder output and plan-shaped work, `to-spec` first collapses the thread into a build spec, published as the Epic's description with no `ready-for-agent` label. Then three shapes, one slicing rule (§5):
- **Multi-slice work** → `to-tickets`: slice, quiz the user on granularity and blocking edges, publish per the tracker doc.
- **Plan-shaped work** → `to-spec`, then the same slicing, published as an Epic with Story children.
- **DecisionRecord-driven single ticket** → one Story created from the bound decision.

Every build spec and ticket names the DecisionRecord ids it rests on. Tickets are created **without** the repository's slug label. They are visible, refinable, and linkable in Jira, and invisible to sandcastle.

**Stage 4: The release decision (human, explicit).** dev-flow presents the decision point: which tickets go to the agent, and how. **Releasing a ticket is applying the slug label** (one CLI command; label *removal* requires the Jira web UI, so labels are applied only at the moment of actual release, never speculatively). Then choose the lane:
- **Batch:** `mise run sandcastle`: the loop works the labeled frontier (§6).
- **Single ticket:** `mise run sandcastle WD-123`.
- **In-session:** the ticket moves to In Progress, and work proceeds via `/implement`, `/gl:commit`, `/gl:create_mr`.

dev-flow's job ends here: label applied, launch command handed over.

**Stage 5: Implementation and review.** Sandcastle's two-phase architecture is unchanged in spirit: Sonnet worker with the Opus `ralph-advisor` in-loop gate, then the Fable reviewer. What changes is branch handling and ticket state (§6, §4).

**Stage 6: Merge request.** After the Fable review passes for a ticket, the **harness** pushes the ticket's branch and opens **one merge request per ticket**, targeting `develop`, title `WD-123: …`, description containing `Closes WD-123`. On the manual path, `/gl:create_mr` does the same.

**Stage 7: Merge and closure.** A human reviews and accepts the MR in GitLab. Acceptance deletes the source branch (project default) and GitLab's Jira integration transitions the ticket to Done. Nobody closes code-bearing tickets by hand, on either path. Commits and MRs mentioning the key have been appearing on the ticket as comments and links throughout, so the web interface tells the truth at every stage.

**Stage 8: Housekeeping.** Single-ticket worktrees are removed by a manual-run `mise` task after their MR merges. The effort's Epic is closed by the human when its implementation children are Done. The decision's predictions are verified at the next session's Stage 0.

## 4. Ticket model and Jira conventions

**Epic per effort.** Every effort gets one Epic in `WD`. For wayfinder efforts, the map *is* the Epic (label `wayfinder:map`). The build spec, when there is one, is the Epic's description. All children link via epic link; blocking edges use Jira's native "is blocked by" issue links.

**Issue types.** Decision tickets: **Task**. Implementation slices: **Story**. Bugs: **Bug**. The two populations stay visually distinct inside the Epic.

**Summary prefix.** `[SLUG]` leads every summary (e.g. `[SDS-BOX]`), from `JIRA_SLUG` in `.claude.env`.

**Labels.**
- Repository slug label (e.g. `sds-box`): **the release gate**. Sandcastle's JQL requires it; absence means invisible to the agent. Decision tickets never receive it.
- `wayfinder:*`: map and decision-ticket bookkeeping.
- `ready-for-agent`: triage vocabulary from the skills; applied at creation to implementation tickets, never to an Epic.

**State model** (statuses: Backlog, Selected for Development, In Progress, Done; every transition is open, so REST transitions work from any state):

| Transition | Actor | When |
|---|---|---|
| → Backlog | to-tickets / jira-planning | At creation |
| Backlog → Selected for Development | Human | Triage: refinable → releasable |
| → In Progress | Worker (AFK) or human/dev-flow (in-session) | At ticket pickup |
| In Progress (stays) | none | Through commit, review, and open MR; stage visible in comments and the MR |
| → Done | **GitLab Jira integration** | MR with `Closes WD-123` merges into `develop` |
| → Selected for Development (bounce) | Fable reviewer | Substantive review failure; comment explains why; no MR opened; label retained so the next run picks it up |

**Close-at-commit is retired everywhere.** The old sandcastle prompt step and the retired `/cl:*` family both closed tickets at commit; that behavior is removed on all paths. Manual closure remains only for tickets with no code attached (pure decisions, Epics, wontfix).

**Upgrade path:** if an "In Review"-type status exists in the workflow editor's add-status picker, it slots between commit and merge. The design works without it.

## 5. The vertical-slice invariant

Stories under an Epic are **vertical slices to the greatest extent possible**, regardless of which path created them: each cuts a narrow but complete path through every layer, is demoable or verifiable on its own, and fits a single fresh context window. Wide mechanical refactors are the exception, sequenced as expand–contract per the `to-tickets` rules.

Ownership split: **to-tickets owns slicing** (its rules and its quiz-the-user step); **jira-planning owns publishing mechanics** (auth bootstrap, curl creation, epic linking, wiki markup). jira-planning's former phase-based decomposition (one story per plan phase, which produced horizontal layers) is retired.

## 6. Implementation machinery

**Naming conventions** (these make the GitLab–Jira linking work):
- Branch: `WD-123-<short-slug>`, cut from `develop`.
- Commits: AFK path `RALPH: WD-123 — description`; manual path `WD-123: description`. Every commit carries the bare uppercase key.
- MR: title `WD-123: …`, description contains `Closes WD-123`, target `develop`. (With the integration active, GitLab also auto-adds the closing line when the branch name contains the key.)

**Batch mode.** The loop works one ticket per iteration, sequentially. Ticket selection is **deterministic frontier preflight**, in code rather than prompt judgment: the JQL returns candidates (slug label + status in Backlog/Selected for Development), then one REST call per candidate fetches `issuelinks`, and any candidate with an inbound "is blocked by" link to a non-Done issue is skipped. Plain JQL cannot traverse links without add-ons, hence the two-step. Each selected ticket gets its own branch off `develop`; the advisor gates plans and diffs in-loop; the Fable reviewer audits the ticket's branch; on pass, the harness pushes and opens the MR. Merge-to-head is retired.

**Waves.** MRs are human-approved, so a ticket's dependents stay excluded until its MR actually merges, even within the same run. Batch runs therefore process the backlog in waves: run, review and merge, run again, and the newly unblocked frontier flows in. A reviewer bounce keeps dependents excluded the same way.

**Single-ticket mode.** `mise run sandcastle WD-123`: same transitions, same branch and MR conventions, existing MR step.

**Manual path.** Ticket → In Progress at start; `/implement` for the work; `/gl:commit` (Jira-key aware) and `/gl:create_mr` for commit and MR; closure at merge, same as the AFK path.

## 7. GitLab–Jira integration

The built-in **Jira issues integration** (GitLab project settings), configured per project:

- **Linking:** commits and MRs mentioning `WD-123` post as comments with web links on the ticket.
- **Closure:** when a commit or MR carrying a closing keyword (`Closes WD-123`) lands in the project's **default branch**, GitLab transitions the issue (configured transition ID, or auto-detected).

Configuration points and caveats (verified against GitLab documentation, 2026-08; re-verify against the self-hosted instance's version at setup):
- Default branch must be `develop`, or auto-closure will not fire on feature merges. Done here means "merged to develop."
- The Jira workflow's transition into Done must carry no screen; a required resolution screen breaks the auto-transition. (The WD Simplified Workflow appears screen-free, an inference from the workflow viewer; verify with one live merge during the pilot.)
- Issue keys must be uppercase in commit messages and MR text.
- Credentials: the GitLab project needs the Jira base URL and a bearer token.
- Optional later additions, deliberately not in scope: the Atlassian DVCS connector (a proper Development panel, ~60-minute refresh) or a marketplace app.

## 8. Onboarding a repository

The pipeline is repository-agnostic. Bringing a new repo in:

1. **GitLab project:** set the default branch to the integration branch (`develop` under git-flow); check `.gitlab-ci.yml` for rules keyed to the old default; enable delete-source-branch-by-default; configure the Jira issues integration (URL, token, comments, transitions).
2. **Identity:** pick the slug label (e.g. `sds-box`) and the `[SLUG]` summary prefix; set `JIRA_SLUG` in `.claude.env`; new tickets must be labeled per the release-gate rule.
3. **Tracker doc:** generate `docs/agents/issue-tracker.md` from the `issue-tracker-jira-dc.md` template (via `/setup-matt-pocock-skills`), including the Wayfinding operations section; adopt the triage label vocabulary.
4. **Sandcastle consumer:** `.sandcastle/` from the fork template; `.env` populated; everything committed before the first run (the sandbox checkout only sees committed content).
5. **Advisor:** `.claude/agents/ralph-advisor.md` present, and `.gitignore` must not blanket-ignore `/.claude/`.
6. **haft:** `haft init` if the repo is to be governed; leave the spec onboarding unrun (§11). Edit `docs/agents/domain.md` to name `.haft/decisions/` as the decision store and `docs/adr/`, if it exists, as frozen history.
7. **Pilot verification:** run one throwaway ticket through the full loop before releasing real work.

## 9. Open items

1. In Review status: check the workflow editor's add-status picker; adopt if available.
2. Verify the self-hosted GitLab version's integration behavior matches current documentation at configuration time.
3. ScriptRunner (or similar) presence on the Jira instance would allow link-traversing JQL and simplify frontier preflight; not assumed, worth checking.
4. Batch frontier discipline in practice: flagged for observation during the pilot.
5. Bert-Legal onboarding later: needs a GitLab remote and migration of its pre-fork `.sandcastle/prompt.md` to the fork template.
6. haft in the sandcastle container: install the CLI pinned to the host's version, have the worker read the governing set for the files it touches before planning, write run-record notes through `haft artifact create` instead of by hand, and have the reviewer run `haft check` and explain any new drift on a governed file. Its own ticket.

## 10. Decision log

| Decision | Choice | Rationale |
|---|---|---|
| Pilot | SDS-Box | Active development, GitLab remote, fork template and haft already in place |
| Done semantics | At MR merge to `develop`, via GitLab integration, both paths | One meaning of Done project-wide; status accuracy was the founding requirement |
| Release gate | Slug label applied at an explicit human decision point | Reuses sandcastle's existing JQL; one switch; protects decision tickets |
| MR policy | One MR per ticket, opened by the harness after Fable review | Deterministic work belongs in code; independent mergeability; clean closure mapping |
| Batch branching | Per-ticket branches off `develop`; frontier-only selection; waves | Every MR independently mergeable; blocked work waits exactly as it would for a human team |
| Reviewer failure | Bounce to Selected for Development with comment | Keeps the ticket in the agent's view; the comment gives the next iteration what it needs |
| Container | Epic per effort; map = Epic; Task/Story/Bug typing | Matches existing jira-planning convention; web-UI traceability |
| Slicing | Vertical slices on all paths; to-tickets owns the rules | Phase-per-story produced horizontal layers; retired |
| Linking | GitLab built-in Jira issues integration only | Zero new infrastructure; also provides closure; DVCS connector deferred |
| `/cl:*` family | Retired | Superseded by `/gl:*` plus this workflow |
| Worktree cleanup | Manual-run task, in scope | Automatic deletion of working directories risks uncommitted work |
| Decision store (2026-10-29) | haft DecisionRecord, bound by the human through `h-decide`; `docs/adr/` frozen as history | One live store; haft carries expiry, drift and verification, which an ADR cannot |
| Record mode (2026-10-29) | Standard when hard to reverse, surprising, and a real trade-off; tactical otherwise; none when no choice was made | Mechanical rule, no judgment at binding time |
| haft spec lifecycle (2026-10-29) | Dormant: no `.haft/specs/` carriers | Half-onboarded drafts forced every decision into tactical mode with spec debt; the skills own the build spec |
| Vocabulary (2026-10-29) | `GLOSSARY.md`, written by `domain-modeling` | The name the skills read since upstream's 2026-08-15 rename; haft's term map belongs to the dormant spec side |
| Build spec (2026-10-29) | `to-spec` output as the Epic description, unlabeled | One place per effort; an Epic is not agent work |

## 11. Artifact ownership: haft and the skills

The skills own how a conversation produces an artifact. haft owns a record that has a lifecycle: expiry, drift, verification, supersession. Where both could hold the same kind, the one with the lifecycle holds it and the other points at it.

| Function | Owner | Record |
|---|---|---|
| Vocabulary | Skills | `GLOSSARY.md` |
| Sharpening an idea | Skills | `grill-with-docs`, in conversation |
| Build spec and tickets | Skills | `to-spec`, `to-tickets`, in Jira |
| Implementation, review, retro | Skills and sandcastle | GitLab |
| A problem framed but not scheduled | haft | ProblemCard, `h-frame` |
| Options compared, when the comparison must be replayable | haft | `h-compare`; conversational by default |
| A decision | haft | DecisionRecord, `h-decide`, bound by the human |
| Findings and rationale from a session | haft | Note, `h-note` |
| Evidence, drift, staleness | haft | `h-verify`, `haft check` |
| System spec | Nobody | `.haft/specs/` absent |

Three facts this rests on, checked 2026-10-29 against haft 9.1.0. With no spec carriers, the spec-binding preflight returns `no_specs` and standard-mode decisions bind unbound; with draft carriers present it returned `draft_section_needed` and blocked standard mode. `haft check` keeps reporting three carrier-missing findings in that state; nothing enforces the check, and only a declared project profile would silence them. haft sees a frozen ADR only through the DecisionRecords that cite its path, so the citation rule in Stage 2 is what keeps the history visible to drift detection.

A build spec is a brief for one piece of work and is disposable after merge. A system spec is a claim about the system that outlives the work; haft's SpecSections are that object, and they are not in use. The two words are kept apart on purpose.
