#!/usr/bin/env bash
# Sync the locally maintained skills fork with Matt Pocock's upstream repo.
#
# Setup this script assumes (done once):
#   - remote `upstream` -> https://github.com/mattpocock/skills
#   - branch `local`    -> your maintained line (all personal refactors live here)
#
# Usage:
#   scripts/sync-upstream.sh              # merge newest upstream release branch
#   scripts/sync-upstream.sh main         # merge upstream/main instead
#   scripts/sync-upstream.sh release/v1.3 # merge a specific upstream branch

set -euo pipefail
root=$(git rev-parse --show-toplevel)
cd "$root"

git remote get-url upstream >/dev/null 2>&1 || {
  echo "No 'upstream' remote. Add it with:" >&2
  echo "  git remote add upstream https://github.com/mattpocock/skills" >&2
  exit 1
}

current=$(git branch --show-current)
if [[ "$current" != "local" ]]; then
  echo "Refusing: this merges into the CURRENT branch ('${current:-detached HEAD}')." >&2
  echo "main and release/* are pristine upstream mirrors — checkout 'local' first." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree is dirty — commit or stash before syncing." >&2
  exit 1
fi

git fetch upstream --prune

# Pick the branch to merge: explicit arg, else the highest-versioned
# upstream release/* branch, else upstream/main.
target="${1:-}"
if [[ -z "$target" ]]; then
  target=$(git branch -r --list 'upstream/release/*' \
    | sed 's|.*upstream/||' | sort -V | tail -1)
  target="${target:-main}"
fi

# Upstream's main and release branches diverge both ways; don't silently
# drop main-only work when defaulting to a release branch.
if [[ "$target" != "main" ]]; then
  main_only=$(git rev-list --count "upstream/$target..upstream/main" 2>/dev/null || echo 0)
  if [[ "$main_only" -gt 0 ]]; then
    echo "Note: $main_only commit(s) on upstream/main are not in $target." >&2
    echo "Re-run as 'scripts/sync-upstream.sh main' to pick them up too." >&2
  fi
fi

echo "Merging upstream/$target into $current..."
if ! git merge --no-ff "upstream/$target" \
  -m "chore: merge upstream/$target into local fork"; then
  if git ls-files -u | grep -q .; then
    cat >&2 <<'EOF'

Merge stopped on conflicts. Expected hotspots:
  - skills/**/SKILL.md you have refactored locally
  - README.md / bucket README.md files
  - .claude-plugin/plugin.json (version + skills array)

Resolve keeping YOUR orchestration/model-tier changes; take upstream's new
skills and content additions. Then: git add -A && git merge --continue.
The `resolving-merge-conflicts` skill can drive this.
EOF
  else
    echo "Merge failed before producing conflicts — see git's message above." >&2
  fi
  exit 1
fi

echo "Done. Review with: git log --oneline -15"
echo "Re-link skills if any were added/renamed: scripts/link-skills.sh"
