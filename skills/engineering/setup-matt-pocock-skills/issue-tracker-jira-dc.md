# Issue tracker: Jira Data Center

Issues and specs for this repo live in **Jira Data Center**, project `WD`, at `https://cfatl-jira.nsapps.dcn/jira`. One Jira project serves every repository; this repo's tickets are scoped by its **slug label** (`<slug>`, e.g. `sds-box`) and its `[SLUG]` summary prefix. `JIRA_SLUG` in `.claude.env` holds the prefix value: if unset, ask the user for one and write it there.

Use curl against the REST API (`$BASE` below) for all writes; `jira-cli` is fine for reads, but its keychain access makes writes unreliable. The instance is slow: 3-minute timeouts, calls run sequentially, never in parallel.

```bash
BASE="https://cfatl-jira.nsapps.dcn/jira/rest/api/2"
```

All commands below were verified against the live instance on 2026-08-26.

## Auth bootstrap: run before the first Jira operation of a session

The bearer token lives in the macOS keychain item `jira-cli`. Validate it:

```bash
TOKEN=$(security find-generic-password -s "jira-cli" -w)
curl -s -o /dev/null -w "%{http_code}" "$BASE/myself" -H "Authorization: Bearer $TOKEN"
```

`200` → proceed. Anything else → capture a fresh token from jira-cli's debug output, re-validate, and store it:

```bash
TOKEN=$(jira issue view WD-52 --debug 2>&1 | grep "Authorization: Bearer" | awk '{print $NF}')
# repeat the /myself check; on 200:
security add-generic-password -s "jira-cli" -a "JoelTurner" -w "$TOKEN" -U
```

If that token also fails, ask the user to run `jira init` in their terminal, then repeat the capture. A `"Field 'summary' cannot be set..."` error on create is a stale token wearing a disguise, not a screen configuration problem; re-run this bootstrap.

## Wiki markup

Descriptions and comments are **Jira wiki markup, not Markdown**: `h2. Heading`, `*bold*`, `{{inline code}}`, `{code:bash}…{code}`, `* bullet`, `# numbered`, `||header||`/`|cell|` tables, `[text|url]`. Inside JSON payloads, newlines are `\n` escapes.

## Conventions

- **Create an issue**: `POST $BASE/issue`, expect `201` with `{"key": "WD-nn"}`. Heredoc via `-d @-` avoids shell-escaping the body:

  ```bash
  curl -s -w "\nHTTP:%{http_code}" -X POST "$BASE/issue" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d @- <<'JSON'
  {"fields": {
    "project": {"key": "WD"},
    "summary": "[SLUG] Title of the ticket",
    "description": "h2. Context\n\nWiki-markup body here.",
    "labels": ["ready-for-agent"],
    "issuetype": {"name": "Story"}
  }}
  JSON
  ```

- **Create an Epic**: same call with `"issuetype": {"name": "Epic"}` plus the Epic Name custom field: `"customfield_11103": "Short epic name"`.
- **Link a child to its Epic**: set the Epic Link custom field at creation: `"customfield_11102": "WD-<epic>"`.
- **"is blocked by" link**: `POST $BASE/issueLink`. Direction is easy to invert; verified: `inwardIssue` is the **blocker**, `outwardIssue` is the **blocked**:

  ```bash
  curl -s -w "HTTP:%{http_code}" -X POST "$BASE/issueLink" \
    -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
    -d '{"type":{"name":"Blocks"},"inwardIssue":{"key":"WD-<blocker>"},"outwardIssue":{"key":"WD-<blocked>"}}'
  ```

- **Labels**: add or remove via update ops on `PUT $BASE/issue/WD-123` (expect `204`):

  ```bash
  -d '{"update":{"labels":[{"add":"<slug>"}]}}'      # release a ticket to the agent
  -d '{"update":{"labels":[{"remove":"<slug>"}]}}'   # pull it back
  ```

  The slug label is the **release gate**: sandcastle's ticket query requires it, so an unlabeled ticket is invisible to the agent. Apply it only at the moment of actual release, never speculatively. Decision tickets never receive it.

- **Transition**: `POST $BASE/issue/WD-123/transitions -d '{"transition":{"id":"31"}}'`, expect `204`. Every transition in the WD workflow is open, so any status is reachable from any other. IDs (verified for this workflow):

  | id | to |
  |----|----|
  | 11 | Backlog |
  | 21 | Selected for Development |
  | 31 | In Progress |
  | 41 | Done |

  When in doubt, list live options with `GET $BASE/issue/WD-123/transitions`.

- **Comment**: `POST $BASE/issue/WD-123/comment -d '{"body":"Wiki-markup text."}'`, expect `201`.
- **List / search**: `GET $BASE/search?jql=<url-encoded JQL>&fields=summary,status,issuelinks&maxResults=50`. JQL cannot *filter* on issue links, but requesting `issuelinks` in `fields` returns each result's links **with the linked issues' statuses inline**, so one call covers candidates and their blockers.
- **View**: `jira issue view WD-123 --comments 5`, or `GET $BASE/issue/WD-123`.
- **Delete**: `DELETE $BASE/issue/WD-123`, expect `204`. Throwaway and scratch tickets only.

## Issue types and state model

Implementation slices are **Story**, decisions are **Task**, bugs are **Bug**: the two populations stay visually distinct inside an Epic.

| Transition | Actor | When |
|---|---|---|
| → Backlog | ticket creation | Always created in Backlog |
| Backlog → Selected for Development | Human | Triage: refinable → releasable |
| → In Progress | Worker (AFK) or the session (in-session) | At ticket pickup |
| → Done | **GitLab Jira integration** | An MR whose description carries `Closes WD-123` merges to `develop` |
| → Selected for Development (bounce) | Reviewer | Substantive review failure, with a comment explaining why |

Code-bearing tickets are closed by the merge, never by hand, on any path. Manual closure is correct only for tickets with no code attached: pure decisions, Epics, wontfix. Commits and MRs carrying the bare uppercase key (`WD-123`) appear on the ticket as comments and links via the GitLab integration, so the ticket tells the truth at every stage.

## When a skill says "publish to the issue tracker"

Create a Jira issue per the conventions above: `[SLUG]` prefix, type by the table, wiki-markup body, epic-linked when the work belongs to an effort, **no slug label** (release is a separate human decision).

## When a skill says "fetch the relevant ticket"

`jira issue view WD-<n> --comments 5`.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an Epic; tickets are its children.

- **Map**: an Epic labelled `wayfinder:map`, its description holding the Notes / Decisions-so-far / Fog body (wiki markup). Update it with `PUT $BASE/issue/WD-<map> -d '{"fields":{"description":"..."}}'`.
- **Child ticket**: a **Task** epic-linked to the map, labelled `wayfinder:<type>` (`research`/`prototype`/`grilling`/`task`). Never the slug label: decision tickets stay invisible to sandcastle.
- **Blocking**: native "is blocked by" links, created as above. A ticket is unblocked when every blocker is Done.
- **Frontier query**: one search, JQL scoped to the map's children and open statuses, with `fields=issuelinks`; drop any result holding an inbound `is blocked by` link to an issue that is not Done; first in key order wins.
- **Claim**: transition to In Progress (id 31), the session's first write.
- **Resolve**: post the answer as a comment, transition to Done (id 41; manual closure is correct here: no code attached), then append a context pointer to the map's Decisions-so-far.
