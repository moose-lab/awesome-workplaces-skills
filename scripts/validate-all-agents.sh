#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

PASS=0
FAIL=0

check() {
  local label="$1"
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label"
    FAIL=$((FAIL + 1))
  fi
}

check_grep() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label"
    FAIL=$((FAIL + 1))
  fi
}

# Auto-detect skills
SKILLS=()
for skill_dir in .agents/skills/*/; do
  if [[ -d "$skill_dir" ]]; then
    SKILLS+=("$(basename "$skill_dir")")
  fi
done

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "No skills found in .agents/skills/" >&2
  exit 1
fi

echo ""
echo "Found ${#SKILLS[@]} skill(s): ${SKILLS[*]}"

# === Global checks ===

echo ""
echo "[Structure: Marketplace]"
check ".claude-plugin/marketplace.json exists" test -f .claude-plugin/marketplace.json
check_grep "marketplace.json contains owner" "owner" .claude-plugin/marketplace.json

echo ""
echo "[Universal]"
check "AGENTS.md exists at root" test -f AGENTS.md
check_grep "README.md mentions Claude Code" "Claude Code" README.md
check_grep "README.md mentions Codex" "Codex" README.md
check_grep "README.md mentions Cursor" "Cursor" README.md
check_grep "README.md mentions Copilot" "Copilot" README.md

# === Per-skill checks ===

for SKILL in "${SKILLS[@]}"; do
  CANONICAL=".agents/skills/$SKILL"
  PLUGIN="$SKILL/skills/$SKILL"

  echo ""
  echo "========================================="
  echo "Skill: $SKILL"
  echo "========================================="

  echo ""
  echo "[Structure: Claude Code]"
  check "$SKILL/.claude-plugin/plugin.json exists" test -f "$SKILL/.claude-plugin/plugin.json"
  check "$PLUGIN/SKILL.md exists" test -f "$PLUGIN/SKILL.md"

  echo ""
  echo "[Structure: Agent Skills Standard]"
  check "$CANONICAL/SKILL.md exists" test -f "$CANONICAL/SKILL.md"
  check "$CANONICAL/agents/openai.yaml exists" test -f "$CANONICAL/agents/openai.yaml"

  # Count reference files
  if [[ -d "$CANONICAL/references" ]]; then
    REF_COUNT=$(ls -1 "$CANONICAL/references/"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ references/ has $REF_COUNT file(s)"
    PASS=$((PASS + 1))
  else
    echo "  ✗ references/ directory missing"
    FAIL=$((FAIL + 1))
  fi

  # Count example files
  if [[ -d "$CANONICAL/examples" ]]; then
    EX_COUNT=$(ls -1 "$CANONICAL/examples/"* 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ examples/ has $EX_COUNT file(s)"
    PASS=$((PASS + 1))
  else
    echo "  ✗ examples/ directory missing"
    FAIL=$((FAIL + 1))
  fi

  echo ""
  echo "[Content: SKILL.md]"
  check_grep "frontmatter contains name: $SKILL" "^name: $SKILL" "$CANONICAL/SKILL.md"

  # Count trigger phrases in description (quoted strings)
  TRIGGER_COUNT=$(grep -A10 "^description:" "$CANONICAL/SKILL.md" | sed '/^---$/q' | grep -oE '"[^"]*"' | wc -l | tr -d ' ')
  if [[ "$TRIGGER_COUNT" -ge 8 ]]; then
    echo "  ✓ description has ≥8 trigger phrases ($TRIGGER_COUNT found)"
    PASS=$((PASS + 1))
  else
    echo "  ✗ description has <8 trigger phrases ($TRIGGER_COUNT found)"
    FAIL=$((FAIL + 1))
  fi

  # Check Verify blocks for each Phase
  PHASE_COUNT=$(grep -c "^## Phase" "$CANONICAL/SKILL.md" 2>/dev/null || echo 0)
  VERIFY_COUNT=$(grep -c "^\*\*Verify Phase" "$CANONICAL/SKILL.md" 2>/dev/null || echo 0)
  if [[ "$VERIFY_COUNT" -ge "$PHASE_COUNT" ]] && [[ "$PHASE_COUNT" -gt 0 ]]; then
    echo "  ✓ All $PHASE_COUNT phases have Verify blocks"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $VERIFY_COUNT Verify blocks for $PHASE_COUNT phases"
    FAIL=$((FAIL + 1))
  fi

  # Check Inputs/Outputs
  INPUT_COUNT=$(grep -c "^\*\*Inputs:\*\*" "$CANONICAL/SKILL.md" 2>/dev/null || echo 0)
  OUTPUT_COUNT=$(grep -c "^\*\*Outputs:\*\*" "$CANONICAL/SKILL.md" 2>/dev/null || echo 0)
  if [[ "$INPUT_COUNT" -ge "$PHASE_COUNT" ]] && [[ "$OUTPUT_COUNT" -ge "$PHASE_COUNT" ]]; then
    echo "  ✓ All $PHASE_COUNT phases have Inputs/Outputs"
    PASS=$((PASS + 1))
  else
    echo "  ✗ Inputs: $INPUT_COUNT, Outputs: $OUTPUT_COUNT for $PHASE_COUNT phases"
    FAIL=$((FAIL + 1))
  fi

  # Count troubleshooting data rows (exclude header and separator rows)
  TROUBLE_ROWS=$(awk '/^## Troubleshooting/{f=1;next} f && /^## /{f=0} f && /^\|/' "$CANONICAL/SKILL.md" | grep -v '^| *[-:]' | tail -n +2 | wc -l | tr -d ' ')
  if [[ "$TROUBLE_ROWS" -ge 8 ]]; then
    echo "  ✓ Troubleshooting table has ≥8 data rows ($TROUBLE_ROWS found)"
    PASS=$((PASS + 1))
  else
    echo "  ✗ Troubleshooting table has <8 data rows ($TROUBLE_ROWS found)"
    FAIL=$((FAIL + 1))
  fi

  echo ""
  echo "[Content: openai.yaml]"
  check_grep "display_name exists" "display_name" "$CANONICAL/agents/openai.yaml"
  check_grep "short_description exists" "short_description" "$CANONICAL/agents/openai.yaml"
  check_grep "default_prompt contains \$$SKILL" "\\\$$SKILL" "$CANONICAL/agents/openai.yaml"
  check_grep "allow_implicit_invocation: true" "allow_implicit_invocation: true" "$CANONICAL/agents/openai.yaml"

  echo ""
  echo "[Consistency: canonical ↔ Claude Code plugin]"

  # SKILL.md
  if diff -q "$CANONICAL/SKILL.md" "$PLUGIN/SKILL.md" > /dev/null 2>&1; then
    echo "  ✓ SKILL.md consistent"
    PASS=$((PASS + 1))
  else
    echo "  ✗ SKILL.md differs"
    FAIL=$((FAIL + 1))
  fi

  # references/
  if [[ -d "$CANONICAL/references" ]]; then
    REF_OK=true
    for f in "$CANONICAL/references/"*; do
      fname=$(basename "$f")
      if ! diff -q "$f" "$PLUGIN/references/$fname" > /dev/null 2>&1; then
        REF_OK=false
        echo "  ✗ references/$fname differs"
        FAIL=$((FAIL + 1))
        break
      fi
    done
    if $REF_OK; then
      echo "  ✓ references/ consistent"
      PASS=$((PASS + 1))
    fi
  fi

  # examples/
  if [[ -d "$CANONICAL/examples" ]]; then
    EX_OK=true
    for f in "$CANONICAL/examples/"*; do
      fname=$(basename "$f")
      if ! diff -q "$f" "$PLUGIN/examples/$fname" > /dev/null 2>&1; then
        EX_OK=false
        echo "  ✗ examples/$fname differs or missing in plugin"
        FAIL=$((FAIL + 1))
        break
      fi
    done
    if $EX_OK; then
      echo "  ✓ examples/ consistent"
      PASS=$((PASS + 1))
    fi
  fi

  # scripts/
  if [[ -d "$CANONICAL/scripts" ]]; then
    SC_OK=true
    for f in "$CANONICAL/scripts/"*; do
      fname=$(basename "$f")
      if ! diff -q "$f" "$PLUGIN/scripts/$fname" > /dev/null 2>&1; then
        SC_OK=false
        echo "  ✗ scripts/$fname differs or missing in plugin"
        FAIL=$((FAIL + 1))
        break
      fi
    done
    if $SC_OK; then
      echo "  ✓ scripts/ consistent"
      PASS=$((PASS + 1))
    fi
  fi

  echo ""
  echo "[Safety]"
  # Check for hardcoded personal emails
  if grep -rn '@gmail.com' "$CANONICAL/" \
    | grep -v 'YOUR_EMAIL@gmail.com' \
    | grep -v 'your-email@gmail.com' \
    | grep -v '@example.com' \
    | grep -v 'user@example.com' \
    | grep -v 'for `@gmail.com`' \
    | grep -q '@gmail.com'; then
    echo "  ✗ Hardcoded personal email found"
    FAIL=$((FAIL + 1))
  else
    echo "  ✓ No hardcoded personal emails"
    PASS=$((PASS + 1))
  fi

  # Check for hardcoded secrets (exclude doc examples with ...)
  if grep -rE '(AIza[a-zA-Z0-9_-]{30,}|ya29\.[a-zA-Z0-9_-]{20,}[^.]|1//[a-zA-Z0-9_-]{20,}|sk-[a-zA-Z0-9]{20,})' "$CANONICAL/" | grep -qv '\.\.\.'; then
    echo "  ✗ Hardcoded secrets/tokens found"
    FAIL=$((FAIL + 1))
  else
    echo "  ✓ No hardcoded secrets/tokens"
    PASS=$((PASS + 1))
  fi

done

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
echo "================================"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
