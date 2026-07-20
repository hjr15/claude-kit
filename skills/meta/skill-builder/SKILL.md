---
name: skill-builder
public: true
bundles: [authoring]
description: Use when creating a new skill from scratch — runs a discovery interview then builds the SKILL.md in the right category/format. For auditing existing skills use library-audit instead.
disable-model-invocation: true
---

## What This Skill Does

Guides the creation and optimization of Claude Code skills using official best practices from the Claude Code documentation. Use this whenever:

- Building a new skill from scratch
- Deciding on advanced features (subagent execution, hooks, dynamic context, etc.)
- Troubleshooting a skill that isn't working correctly

To **audit or optimise an existing skill**, use the `library-audit` skill instead — it
owns the per-skill hygiene lenses (visibility / determinism / composability) and the
library-wide review.

For frontmatter fields and advanced patterns, follow the official Claude Code skills
documentation (the `claude-code-guide` agent can answer specifics).

## Mode 1: Build a New Skill

When building a new skill, run the **Discovery Interview** first. Do NOT start writing files until discovery is complete.

### Discovery Interview

Ask questions using AskUserQuestion, one round at a time. Each round covers one topic. Move to the next round only after the user answers. Keep going until you're 95% confident you understand the skill well enough to build it without further clarification.

**Round 1: Goal & Name**
- What does this skill do? What problem does it solve or what workflow does it automate?
- What should we call it? (Suggest a name based on their answer -- lowercase, hyphens, max 64 chars)

**Round 2: Trigger**
- What would someone say to trigger this? (Get 2-3 natural language phrases)
- Should it be user-only (`/slash-command`), Claude-auto-invocable, or both?
- Does it accept arguments? If so, what? (e.g., a topic, a URL, a file path)

**Round 3: Step-by-Step Process**
- Walk me through exactly what should happen from trigger to output. What's step 1? Step 2? Keep going.
- For each step: Does Claude do it directly, or delegate to a subagent/script?
- Does this need to be conversational (back-and-forth with the user) or is it a fire-and-forget task?

**Round 4: Inputs, Outputs & Dependencies**
- What inputs does the skill need? (Files, API responses, user arguments, live data)
- What does it produce? (Files, text output, structured data) Where do outputs go?
- Does it need external APIs, scripts, or tools? Which ones?
- Does it need reference files, style guides, templates, or examples?

**Round 5: Guardrails & Edge Cases**
- What could go wrong? What are the common failure modes?
- What should this skill NOT do? Any hard boundaries?
- Are there cost concerns? (API calls, AI image generation, etc.)
- Any ordering or dependency constraints? (e.g., "must check X before doing Y")

**Round 6: Confirmation**
After all rounds, summarize your understanding back to the user in this format:

```
## Skill Summary: [name]

**Goal:** [one sentence]
**Trigger:** `/name` + [natural language phrases]
**Arguments:** [what it accepts, or "none"]

**Process:**
1. [step]
2. [step]
...

**Inputs:** [what it reads/needs]
**Outputs:** [what it produces + where]
**Dependencies:** [APIs, scripts, agents, reference files]
**Guardrails:** [what can go wrong, what to avoid]
```

Ask: "Does this capture it? Anything to add or change?" Only proceed to building once the user confirms.

**Skipping rounds:** If the user provides enough context upfront (e.g., they describe the full workflow in their first message), skip rounds that are already answered. Don't re-ask what you already know.

### Build Phase

Once discovery is complete, build the skill following these steps:

**Step 1: Choose the skill type**

- **Task skills** (most of ours) give step-by-step instructions for a specific action. Invoked with `/name` or natural language.
- **Reference skills** add knowledge Claude applies to current work. Conventions, patterns, style guides.

**Step 2: Configure frontmatter**

Set these fields based on what you learned in discovery:

- `name` -- Matches the directory name.
- `description` -- The ONLY thing Claude sees when deciding whether to load the skill, so make it **disambiguating**, not generic. Max 1024 chars. House style: lead with "Use when someone asks to [action], [action], or [action]" then "— [what it does]", using natural keywords from the trigger phrases.
  - Bad: `Helps with documents.` — gives Claude no way to tell this from any other document skill.
  - Good: `Use when someone asks to read, parse, or pull data out of a PDF (including scanned / image PDFs needing OCR) — extracts text and tables from PDF files.`
- `disable-model-invocation: true` -- Set if the skill has side effects (file generation, API calls, costs money).
- `argument-hint` -- Set if the skill accepts arguments.
- `context: fork` + `agent` -- Set if the skill is self-contained and doesn't need conversation history.
- `model` -- Set if a specific model capability is needed.
- `allowed-tools` -- Set if the skill should have restricted tool access.

**Step 3: Write the skill content**

Structure task skills as:
1. **Context** -- Files to read, APIs, brand assets, agent prompts
2. **Step-by-step workflow** -- Numbered steps. Each step tells Claude exactly what to do.
3. **Output format** -- What the result looks like. Include templates, file paths, structured formats.
4. **Notes** -- Edge cases, constraints, what to delegate, what NOT to do.

Content rules:
- Keep SKILL.md under 500 lines. Move detailed reference to supporting files.
- No time-sensitive info — skills are long-lived. State durable facts, not "as of vX" / dated specifics that rot.
- Reference files one level deep — SKILL.md → `reference.md`, not SKILL.md → A → B. Don't make Claude chain-load.
- Use `$ARGUMENTS` / `$N` for dynamic input from arguments.
- Use `!`command`` for dynamic context injection (preprocessing).
- Be specific about agent delegation -- include exact prompt text.
- Specify all file paths (inputs, outputs, scripts, references).

**Step 4: Add supporting files (if needed)**

```
my-skill/
 SKILL.md           # Main instructions (required, <500 lines)
 reference.md       # Detailed docs (loaded when needed)
 examples/
   sample.md        # Example output
 scripts/
   helper.py        # Utility script
```

Reference these from SKILL.md so Claude knows they exist and when to load them.

**Step 5: Place it for auto-discovery**

`skills/README.md` is the source of truth for layout. In short:
- **Format A (auto-discovered):** `skills/<category>/<slug>/SKILL.md`, where `<category>`
  is `meta/`, `workflow/`, `docs/`, or `frontend/`. Use this for anything Claude should
  invoke on its own. No manual registry — discovery is automatic.
- **Format B (flat playbook):** `skills/<namespace>/<name>.md`, loaded only when
  `@`-referenced (e.g. the `atlassian/` jira-* family). Use for reference playbooks.

There is no CLAUDE.md "Active Skills" registry and no decision log to update — the
deploy step (`scripts/install.sh`) fans skills out to `~/.claude/`.

**Step 6: Test**

1. **Natural language** -- Say something matching the description. Check if Claude loads it.
2. **Direct invocation** -- Run `/skill-name` with test arguments.

To **audit** the result, hand off to the `library-audit` skill.

---

## Project conventions (claude-config)

`skills/README.md` is the authoritative layout doc; the essentials:

- Skills live under `skills/<category>/<slug>/SKILL.md` (Format A) or flat
  `skills/<namespace>/<name>.md` (Format B). Deployed via `scripts/install.sh`.
- New-skill candidates are harvested into `skills/skill-candidates.md` by the
  `session-harvest` skill — check there before building, a candidate may already exist.
- API keys are read from `.env` with placeholders documented; never hard-code secrets.
- Frontmatter `description` is written as: "Use when [trigger] -- [what it does]."
- Set `disable-model-invocation: true` on any skill with side effects (writes files,
  calls paid APIs, transitions tickets) so it only fires on explicit invocation.

## Important Notes

- **Route "make this the standard" feedback to the canonical source.** When a
  user corrects a skill's output and says "do it this way going forward," edit the
  standing rule in `claude-config/skills/.../SKILL.md`, NOT the deployed
  `~/.claude/skills/` copy (which redeploy overwrites). Resolve the deployed path
  back first with `readlink -f`, check the source repo's branch/status for
  cross-repo safety, then edit + commit there.
- **Helper scripts must resolve for both install modes.** A skill that ships
  scripts and is both `/plugin install`-able and clonable-as-template breaks if it
  calls scripts by repo-relative paths (in plugin mode the code lives in the
  plugin cache, not cwd). Resolve engine-script paths via
  `${CLAUDE_PLUGIN_ROOT:-${CLAUDE_PROJECT_DIR:-.}}`, anchor the user-data
  workspace under `CLAUDE_PROJECT_DIR`, and have the scaffold write its gitignore
  rules there so privacy holds in plugin mode.
- Always read the existing skill before optimizing it. Never propose changes to code you haven't read.
- When building a new skill, check if a similar skill already exists that could be extended instead.
- Skills and agents work together in two directions: skills can run inside agents (`context: fork` + `agent`), and agents can preload skills (`skills` field in agent frontmatter). Choose the right direction based on who controls the system prompt.
- Skill descriptions are loaded into context. If there are many skills, they may exceed the character budget (2% of context window, fallback 16,000 chars). Keep descriptions concise.
- The `/` menu only shows skills where `user-invocable` is not `false`. Use `user-invocable: false` for background knowledge skills.
- `disable-model-invocation: true` is the strongest restriction -- it removes the skill from Claude's context entirely and prevents programmatic invocation via the Skill tool.
