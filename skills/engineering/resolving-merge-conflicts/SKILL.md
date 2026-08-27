---
name: resolving-merge-conflicts
description: "Use when you need to resolve an in-progress git merge/rebase conflict."
---

Before resolving any hunk, trace each side back to its primary sources (commit messages, PRs, original issues) to recover the intent behind both changes. Resolve preserving both intents where possible; where they are incompatible, pick the side matching the merge's stated goal and note the trade-off. Do not invent new behaviour. Run the project's checks, fix what the merge broke, and complete the merge or rebase through to the final commit.

Always resolve rather than `--abort`; if the two intents are genuinely irreconcilable, stop and ask the user instead of inventing a resolution.
