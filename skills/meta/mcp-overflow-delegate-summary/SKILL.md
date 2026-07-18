---
name: mcp-overflow-delegate-summary
public: true
bundles: [authoring]
description: Use when an MCP tool result is dumped to a tool-results/*.txt file because it exceeded the token cap — delegate the read+summarize to a general-purpose subagent (or jq the file for targeted extraction) so the raw payload stays out of the main context.
---

# MCP Overflow → Delegate Summary

## Overview

MCP tool results that exceed the token cap are spilled to a `tool-results/*.txt` file with a message telling you to read it in chunks. **Don't read it back into the main context** — reading chunks re-introduces the bytes that were too big to fit. Either delegate a full read+summarize to a subagent, or `jq` the file for a targeted extraction.

## When to Use

- Any MCP tool result returns "Error: result (X characters) exceeds maximum allowed tokens. Output has been saved to /path/to/tool-results/*.txt"
- The file is JSON/structured data and you need an extract or summary
- The data would otherwise need manual offset/limit Read skimming

## Two paths

**Targeted extraction (counts, one field, a filter) → `jq` from the main context.** Faster than a subagent round-trip. The file is on disk; parse it directly:

```bash
jq -r '.issues.nodes[] | "\(.key) [\(.fields.issuetype.name)] parent=\(.fields.parent.key // "NONE")"' /path/to/tool-results/X.txt
```

**Multi-page bulk result (a whole-project query that overflows on *every* page) → paginate at the edge, reduce each page to TSV, then analyse offline.** Never re-read a giant JSON page into context. Loop: probe structure once (`jq 'type, (.issues.nodes|length), .issues.pageInfo' <file>`); per page append a compact TSV (`jq -r '.issues.nodes[] | [.key, .fields.status.name, (.fields.parent.key//""), ...] | @tsv' <file> >> all.tsv`); paginate via `pageInfo.endCursor` / `nextPageToken` until `hasNextPage=false`; then run the actual analysis (orphans, roll-up consistency, staleness) with `python3`/`awk` over the small `all.tsv`. Scriptable and repeatable, and the raw payload never enters context.

**Full-content read + structured summary → delegate to a `general-purpose` subagent.** The subagent's full read sits in *its* context, which the orchestrator discards; only the summary returns. Dispatch with an explicit, structured prompt:

- Give it the **full file path** verbatim
- Tell it what fields to extract (list them exactly)
- Specify return shape — compact markdown table, JSON, prose paragraph
- Note that JSON files do NOT chunk safely — they must be parsed whole
- Cap return length explicitly ("under 300 words", "table only")
- Tell it explicitly NOT to make decisions / recommendations — just inventory

Example prompt shape:

```
Read /path/to/tool-results/X.txt. It's a JSON result from MCP tool Y listing N items.
For each item extract <fields>. Return a markdown table grouped by <axis>, columns
<list>. Include EVERY item — no sampling. Then add a <150-word patterns paragraph.
Do NOT recommend; just inventory.
```

## Gotcha — narrowing `fields` doesn't shrink the response

`searchJiraIssuesUsingJql` (and similar list tools) do **not** trim the payload when you pass a narrow `fields` allowlist — descriptions, the bulk of the size, come back regardless. Shrink the result by tightening the JQL / lowering the result count, not by trimming `fields`.

## Why subagent, not me

- Main-context tokens stay clean for downstream decisions
- The subagent's full read is discarded with its context
- Forces an explicit extract spec — better signal-to-noise than a free-form skim
