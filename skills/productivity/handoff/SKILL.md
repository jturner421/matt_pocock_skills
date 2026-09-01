---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS - not the current workspace.

Preserve these even at the cost of length, and keep everything else concise:

- difficulties that came up, and how they were handled or resolved
- options or approaches raised, tried, or set aside, and why
- anything asked for, decided, agreed, ruled out, or established as a preference, constraint, or boundary, stated exactly
- exactly where things stand: what is covered, settled, or completed
- anything still open, promised, or expected to happen next
- details that would be hard to reconstruct (names, numbers, dates, exact wording, links), kept exactly

Keep what the user said, asked for, or established close to their own words; condense your own reasoning to what it concluded or produced.

Write the document in plain, literal language: short sentences, one idea per paragraph, terms spelled out on first use, and a literal phrase wherever one exists instead of a metaphor.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
