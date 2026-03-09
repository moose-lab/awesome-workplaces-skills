# Gmail Waitlist Codex Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Codex-compatible skill metadata and documentation so the `gmail-waitlist` skill can be installed and explicitly invoked from Codex.

**Architecture:** Keep the existing skill content and Claude plugin layout intact. Add Codex-facing metadata inside the skill folder, document Codex installation and `$gmail-waitlist` invocation in the repository README, and add a lightweight validation script that checks the required Codex files and text are present.

**Tech Stack:** Markdown, YAML, shell validation script

### Task 1: Record the current missing Codex support

**Files:**
- Modify: `docs/plans/2026-03-09-gmail-waitlist-codex-support.md`
- Test: repository root shell commands

**Step 1: Write the failing test**

```bash
test -f gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml
rg -n "Codex" README.md
```

**Step 2: Run test to verify it fails**

Run: `test -f gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml`
Expected: exit status `1`

Run: `rg -n "Codex" README.md`
Expected: exit status `1`

### Task 2: Add Codex skill metadata

**Files:**
- Create: `gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml`
- Modify: `gmail-waitlist/skills/gmail-waitlist/SKILL.md`

**Step 1: Write the failing test**

```bash
test -f gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml
```

**Step 2: Run test to verify it fails**

Run: `test -f gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml`
Expected: exit status `1`

**Step 3: Write minimal implementation**

Add `agents/openai.yaml` with:
- `interface.display_name`
- `interface.short_description`
- `interface.default_prompt` referencing `$gmail-waitlist`

Only adjust `SKILL.md` if the description needs stronger Codex trigger coverage.

**Step 4: Run test to verify it passes**

Run: `test -f gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml`
Expected: exit status `0`

### Task 3: Document Codex installation and one-click invocation

**Files:**
- Modify: `README.md`

**Step 1: Write the failing test**

```bash
rg -n "Codex" README.md
rg -n '\$gmail-waitlist' README.md
```

**Step 2: Run test to verify it fails**

Run: `rg -n "Codex" README.md`
Expected: exit status `1`

Run: `rg -n '\$gmail-waitlist' README.md`
Expected: exit status `1`

**Step 3: Write minimal implementation**

Add:
- Codex-compatible repository description
- Local install path example for `~/.codex/skills/gmail-waitlist`
- Explicit invocation example using `$gmail-waitlist`

**Step 4: Run test to verify it passes**

Run: `rg -n "Codex" README.md`
Expected: matching lines returned

Run: `rg -n '\$gmail-waitlist' README.md`
Expected: matching lines returned

### Task 4: Add lightweight validation

**Files:**
- Create: `scripts/validate-codex-skill-support.sh`

**Step 1: Write the failing test**

```bash
test -x scripts/validate-codex-skill-support.sh
```

**Step 2: Run test to verify it fails**

Run: `test -x scripts/validate-codex-skill-support.sh`
Expected: exit status `1`

**Step 3: Write minimal implementation**

Create an executable shell script that checks:
- `SKILL.md` exists
- `agents/openai.yaml` exists
- `default_prompt` references `$gmail-waitlist`
- `README.md` mentions Codex and `$gmail-waitlist`

**Step 4: Run test to verify it passes**

Run: `test -x scripts/validate-codex-skill-support.sh`
Expected: exit status `0`

### Task 5: Validate the completed skill

**Files:**
- Read: `gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml`
- Read: `README.md`

**Step 1: Run repository validation**

Run: `scripts/validate-codex-skill-support.sh`
Expected: success output with all checks passing

**Step 2: Run skill validation**

Run: `python3 /Users/moose/.codex/skills/.system/skill-creator/scripts/quick_validate.py gmail-waitlist/skills/gmail-waitlist`
Expected: validation passes
