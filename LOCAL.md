# Locally maintained fork

This checkout is a personal fork of [mattpocock/skills](https://github.com/mattpocock/skills),
maintained locally with refactored skills (model-tiered subagent orchestration,
Claude 5-generation context engineering). This file and everything it describes
exist only in the fork — upstream never sees them, so they never conflict.

## Layout

- Remote `upstream` — Matt Pocock's repo. Read-only; fetch from it, never push.
- Branch `local` — the maintained line. All personal refactors and additions
  are committed here.
- Branches `main` / `release/v1.2` — pristine mirrors of upstream, kept only
  as reference points.
- (Optional) Remote `origin` — your own GitHub repo for backup:
  `gh repo create <you>/skills --private --source=. --remote=origin` then
  `git push -u origin local`.

## Pulling new upstream work

```bash
scripts/sync-upstream.sh
```

By default it merges the newest `upstream/release/*` branch (Matt lands new
work on release branches ahead of `main`); pass a branch name to override.
On conflicts, keep the local orchestration/model-tier edits, take upstream's
new skills and content, then `git merge --continue`. After a sync that adds or
renames skills, re-run `scripts/link-skills.sh`.

## Local conventions that differ from upstream

- Skills refactored here follow the Claude 5 context-engineering rules:
  short SKILL.md files that trust model judgment, progressive disclosure via
  reference files, no repeated instructions across layers.
- Skills that fan out subagents declare their worker model inline at the spawn
  point. `.agents/orchestration.md` holds the fork-level view: the advisor
  pattern, the loop architecture, and the per-skill orchestrator-seat table.
- The aihero.dev docs-page requirement in CLAUDE.md is upstream's publishing
  concern; the fork does not create or re-sync `docs/` pages for skills it
  adds **or modifies** — upstream's pages drift from the fork's behaviour and
  that is accepted.
