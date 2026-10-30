# Integrated Development Workflow: Design

**Written:** 2026-08-26. **Revised:** 2026-10-30. **Status:** implemented; the pilot ran on SDS-Box on 2026-08-26. The surviving pilot record is `SDS-Box/docs/dev-flow-runbook.md` and `SDS-Box/docs/pilot-notes.md`; the implementation work order the first version named was not kept.
**Pilot repository:** SDS-Box. The pipeline itself is repository-agnostic; see §8.

This document is the authority for target behavior.

## 1. Purpose and scope

A single integrated process that takes work from first discussion to closed ticket, using tools that already exist in this environment:

- **Session skills** (Matt Pocock skills fork at `/Users/jwt/skills`, linked globally): `wayfinder`, `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `handoff`, `prototype`, plus the rest of the engineering bucket. `dev-flow` itself is a fork-owned skill in the same tree.
- **haft** (`.haft/` in governed repos): the durable project memory: problems, decisions, notes, evidence, and what has gone stale. Its specification lifecycle is not used (§11).
- **Jira Data Center** (`https://cfatl-jira.nsapps.dcn/jira`, project `WD`): all tickets for all repos, scoped per-repo by slug labels.
- **Sandcastle fork** (`/Users/jwt/sandcastle`, branch `local`): the AFK implementation loop: Sonnet worker with the Opus `ralph-advisor` in-loop gate, a gated Codex second review, and an Opus 5.5 reviewer whose verdict decides the merge request. Its sandbox image carries the pinned haft CLI. The fork's own decisions are in its `docs/adr/` up to ADR 0024 (2026-10-30) and in `.haft/decisions/` after that.
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
| Sandcastle fork | `/Users/jwt/sandcastle` (branch `local`) | AFK loop: batch mode and single-ticket mode; the worker, Codex and reviewer phases, the verdict, the merge request |
| Per-repo consumer | `<repo>/.sandcastle/` | Dockerfile (court CAs, pinned Codex CLI, pinned haft CLI), prompts, entry scripts, env for the loop |
| Codex login | host `~/.codex/auth.json` | Credential for the Codex second review; a copy without the refresh token is mounted into that phase's sandbox only |
| haft | `<repo>/.haft/` and the host CLI, at the version the fork pins | Project memory: ProblemCards, DecisionRecords, notes, evidence. The loop's run records are notes here |
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

**Stage 5: Implementation and review.** Three phases per ticket, each in a fresh container on the ticket's branch (fork ADRs 0021, 0022, 0024):
- **Worker** (Sonnet) with the Opus `ralph-advisor` gating its plan and its diff. Before the agent starts, the sandbox creates haft's project database from the repo's `.haft/project.yaml`; the worker reads the decisions that govern the files it touches (`haft decision governing-set`, `haft graph explore`) and the earlier run records, implements test-first, commits as `RALPH: WD-123 — …`, comments on the ticket, and writes its run record as a haft note (`<KEY> run record (worker)`) through `haft artifact create`, by hand in the same layout if haft fails.
- **Codex second review**, only on tickets the gate selects (`--codex-review=always|never`, else a `codex-review` or `no-codex-review` ticket label, else under `auto`: attempt 2, a path in the entry script's risk globs, or more non-test changed lines than its threshold). A read-only Codex run returns structured findings, each with a severity and a `breaksRequirement` flag. A failed Codex phase halts the run: no reviewer, no merge request, the ticket stays In Progress, a resume file is written, and `main.mts WD-123 --resume-review` continues from this phase.
- **Reviewer** (Opus 5.5) audits the branch against the ticket, runs the quality gates, adjudicates every Codex finding (`fixed`, `rejected`, `deferred`), fixes what it can as `RALPH-REVIEW: WD-123 — …`, runs `haft check` and reports new drift on a decision the diff touched, writes its own run record, and ends with a **verdict**: `pass`, `retry`, or `draft`.

**Stage 6: Merge request.** Every reviewed ticket ends in a merge request opened by the **harness**: one per ticket, targeting `develop`, title `WD-123: …`, description containing `Closes WD-123` and a "Second review (Codex)" section. A `pass` opens a normal merge request. A `draft` opens a draft merge request carrying the reviewer's objections, which GitLab will not merge; a `critical`, `high`, or requirement-breaking Codex finding left unfixed turns a `pass` into a draft. A `retry` is allowed once per ticket, on attempt 1 only: the reviewer has moved the ticket back to Selected for Development with a different approach as the comment, no merge request opens, and the next run works the same branch as attempt 2 with that comment as its brief. On the manual path, `/gl:create_mr` opens the merge request.

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
| → Selected for Development (retry) | Reviewer, verdict `retry`, attempt 1 only | The work needs a different approach the reviewer can state; comment is the next worker's brief; no MR opened; label retained. On attempt 2 the harness treats `retry` as `draft` |
| In Progress (stays), draft MR | Reviewer, verdict `draft`, or an unfixed major Codex finding | Not fit to merge as is; a draft MR carries the objections; the human decides: fix on the branch, close the draft and send the ticket back (next run starts fresh at attempt 1), or send it back with the draft open (next run is attempt 2 on the same branch) |

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

**Batch mode.** The loop works one ticket per iteration, sequentially. Ticket selection is **deterministic frontier preflight**, in code rather than prompt judgment: the JQL returns candidates (slug label + status in Backlog/Selected for Development), then one REST call per candidate fetches `issuelinks`, and any candidate with an inbound "is blocked by" link to a non-Done issue is skipped. Plain JQL cannot traverse links without add-ons, hence the two-step. Each selected ticket gets its own branch off `develop`; the advisor gates plans and diffs in-loop; the Codex gate is decided on the host after the worker commits; the reviewer audits the ticket's branch and emits the verdict; the harness pushes and opens the MR, normal or draft. Merge-to-head is retired.

**Launch check.** Unless `--codex-review=never`, the entry script checks on the host, before any sandbox is built, that `~/.codex/auth.json` exists and its access token outlasts the run's margin, and probes Codex once in the sandbox image. A failure aborts the run and prints the fix. A gated ticket whose Codex phase fails mid-run halts the run with `.sandcastle/logs/<KEY>.resume.json`; the remaining tickets stay queued, and `--resume-review` continues that ticket from the Codex phase with no new worker run.

**Waves.** MRs are human-approved, so a ticket's dependents stay excluded until its MR actually merges, even within the same run. Batch runs therefore process the backlog in waves: run, review and merge, run again, and the newly unblocked frontier flows in. A reviewer bounce keeps dependents excluded the same way.

**Single-ticket mode.** `mise run sandcastle WD-123`: same transitions, same branch and MR conventions, same three phases. `WD-123 --resume-review` continues a halted ticket.

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
4. **Sandcastle consumer:** `.sandcastle/` from the fork template; `.env` populated; the image built (`sandcastle docker build-image`, which downloads the pinned haft release); everything committed before the first run (the sandbox checkout only sees committed content). Host prerequisites are in the fork's `docs/local-fork.md`: `glab`, a Jira token, Claude Code auth, a Codex login (or runs with `--codex-review=never`), and haft at the fork's pinned version.
5. **Advisor:** `.claude/agents/ralph-advisor.md` present, and `.gitignore` must not blanket-ignore `/.claude/`.
6. **haft:** `haft init` if the repo is to be governed; leave the spec onboarding unrun (§11). Edit `docs/agents/domain.md` to name `.haft/decisions/` as the decision store and `docs/adr/`, if it exists, as frozen history.
7. **Pilot verification:** run one throwaway ticket through the full loop before releasing real work.

## 9. Open items

1. In Review status: check the workflow editor's add-status picker; adopt if available.
2. Verify the self-hosted GitLab version's integration behavior matches current documentation at configuration time.
3. ScriptRunner (or similar) presence on the Jira instance would allow link-traversing JQL and simplify frontier preflight; not assumed, worth checking.
4. Batch frontier discipline in practice: flagged for observation during the pilot.
5. Bert-Legal onboarding later: needs a GitLab remote and migration of its pre-fork `.sandcastle/prompt.md` to the fork template.
6. ~~haft in the sandcastle container~~ Done 2026-10-30 in sandcastle fork 0.15.0 (its ADR 0024): the jira-dc image installs haft pinned by `HAFT_VERSION`, the sandbox bootstraps the project database at start, the worker reads the governing set (`haft decision governing-set`, `haft graph explore`) before planning and writes its run record through `haft artifact create note.record`, and the reviewer runs `haft check` and reports new drift on a decision the diff touched. Hand-written notes remain the fallback when haft fails.

## 10. Decision log

| Decision | Choice | Rationale |
|---|---|---|
| Pilot | SDS-Box | Active development, GitLab remote, fork template and haft already in place |
| Done semantics | At MR merge to `develop`, via GitLab integration, both paths | One meaning of Done project-wide; status accuracy was the founding requirement |
| Release gate | Slug label applied at an explicit human decision point | Reuses sandcastle's existing JQL; one switch; protects decision tickets |
| MR policy | One MR per ticket, opened by the harness after the reviewer's verdict; a draft when the verdict is `draft` | Deterministic work belongs in code; independent mergeability; clean closure mapping |
| Batch branching | Per-ticket branches off `develop`; frontier-only selection; waves | Every MR independently mergeable; blocked work waits exactly as it would for a human team |
| Reviewer failure | `retry` once per ticket (bounce to Selected for Development with a comment); otherwise `draft` (fork ADR 0021) | Keeps the ticket in the agent's view; the comment gives the next iteration what it needs; a draft never merges unseen |
| Second review (2026-10-29) | Gated Codex adversarial review between worker and reviewer; the reviewer adjudicates each finding; an unfixed major finding forces a draft; a failed phase halts the run and resumes by command (fork ADR 0022) | A second model family on trust boundaries, races and data loss, without replacing the reviewer; the harness, not a prompt, keeps it read-only and decides what a disagreement means |
| haft in the sandbox (2026-10-30) | Pinned haft CLI in the jira-dc image; database bootstrapped at sandbox start; run records through `haft artifact create`; reviewer runs `haft check` (fork ADR 0024) | The loop reads the governing decisions it must not drift from and writes notes the host's `haft sync` imports; hand-written notes stay the fallback |
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
| Implementation, review, retro | Skills and sandcastle | GitLab, plus the loop's run records as haft notes (`<KEY> run record (worker)` and `(reviewer)`) |
| A problem framed but not scheduled | haft | ProblemCard, `h-frame` |
| Options compared, when the comparison must be replayable | haft | `h-compare`; conversational by default |
| A decision | haft | DecisionRecord, `h-decide`, bound by the human |
| Findings and rationale from a session | haft | Note, `h-note` |
| Evidence, drift, staleness | haft | `h-verify`, `haft check` |
| System spec | Nobody | `.haft/specs/` absent |

Three facts this rests on, checked 2026-10-29 against haft 9.1.0. With no spec carriers, the spec-binding preflight returns `no_specs` and standard-mode decisions bind unbound; with draft carriers present it returned `draft_section_needed` and blocked standard mode. `haft check` keeps reporting three carrier-missing findings in that state; nothing enforces the check, and only a declared project profile would silence them. haft sees a frozen ADR only through the DecisionRecords that cite its path, so the citation rule in Stage 2 is what keeps the history visible to drift detection.

A build spec is a brief for one piece of work and is disposable after merge. A system spec is a claim about the system that outlives the work; haft's SpecSections are that object, and they are not in use. The two words are kept apart on purpose.
