---
name: research
description: Investigate a question against high-trust primary sources and capture the findings as a Markdown file in the repo. Use when the user wants a topic researched, docs or API facts gathered, or reading legwork delegated to a background agent.
---

Spin up a **background agent** to do the research, so you keep working while it reads. For a single fact you can confirm from one source, answer directly; the background agent is for research with real reading legwork.

Run it on a Sonnet-class model (`model: "sonnet"`): following sources and taking cited notes is worker-shaped. If the findings will arbitrate conflicting sources or drive an architectural choice, review the written note critically yourself before relying on it.

Tell it what decision or question the findings feed, not just the question itself; it reads more usefully when it knows the intent.

Its job:

1. Investigate the question against **primary sources** (official docs, source code, specs, first-party APIs), not a secondary write-up of them. Follow every claim back to the source that owns it.
2. Write the findings to a single Markdown file, citing each claim's source. Mark any source wording reproduced verbatim as a quotation; restate everything else in your own words. Write the note in plain, literal language: short sentences, one idea per paragraph, terms spelled out on first use, and a literal phrase wherever one exists instead of a metaphor.
3. Save it where the repo already keeps such notes; match the existing convention, and if there is none, put it somewhere sensible and say where.
