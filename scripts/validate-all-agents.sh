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

check_not_grep() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  if ! grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "  ✓ $label"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $label"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "[Structure: Claude Code]"
check ".claude-plugin/marketplace.json exists" test -f .claude-plugin/marketplace.json
check_grep "marketplace.json contains owner" "owner" .claude-plugin/marketplace.json
check "gmail-waitlist/.claude-plugin/plugin.json exists" test -f gmail-waitlist/.claude-plugin/plugin.json
check "gmail-waitlist/skills/gmail-waitlist/SKILL.md exists" test -f gmail-waitlist/skills/gmail-waitlist/SKILL.md

echo ""
echo "[Structure: Agent Skills Standard]"
check ".agents/skills/gmail-waitlist/SKILL.md exists" test -f .agents/skills/gmail-waitlist/SKILL.md
check ".agents/skills/gmail-waitlist/agents/openai.yaml exists" test -f .agents/skills/gmail-waitlist/agents/openai.yaml
check "references/ has 4 files" test "$(ls -1 .agents/skills/gmail-waitlist/references/*.md 2>/dev/null | wc -l | tr -d ' ')" -eq 4
check "examples/ has 4 files" test "$(ls -1 .agents/skills/gmail-waitlist/examples/* 2>/dev/null | wc -l | tr -d ' ')" -eq 4
check "scripts/extract-refresh-token.js exists" test -f .agents/skills/gmail-waitlist/scripts/extract-refresh-token.js

echo ""
echo "[Content: SKILL.md]"
check_grep "frontmatter contains name: gmail-waitlist" "^name: gmail-waitlist" .agents/skills/gmail-waitlist/SKILL.md
# Count trigger phrases in description
TRIGGER_COUNT=$(grep -A5 "^description:" .agents/skills/gmail-waitlist/SKILL.md | grep -oE '"[^"]*"' | wc -l | tr -d ' ')
if [[ "$TRIGGER_COUNT" -ge 8 ]]; then
  echo "  ✓ description has ≥8 trigger phrases ($TRIGGER_COUNT found)"
  PASS=$((PASS + 1))
else
  echo "  ✗ description has <8 trigger phrases ($TRIGGER_COUNT found)"
  FAIL=$((FAIL + 1))
fi
check_grep "Phase 1 has Verify block" "Verify Phase 1" .agents/skills/gmail-waitlist/SKILL.md
check_grep "Phase 2 has Verify block" "Verify Phase 2" .agents/skills/gmail-waitlist/SKILL.md
check_grep "Phase 3 has Verify block" "Verify Phase 3" .agents/skills/gmail-waitlist/SKILL.md
check_grep "Phase 4 has Verify block" "Verify Phase 4" .agents/skills/gmail-waitlist/SKILL.md
check_grep "Phase 5 has Verify block" "Verify Phase 5" .agents/skills/gmail-waitlist/SKILL.md
check_grep "Phase 1 has Inputs" "^\*\*Inputs:\*\*" .agents/skills/gmail-waitlist/SKILL.md
check_grep "Phase 1 has Outputs" "^\*\*Outputs:\*\*" .agents/skills/gmail-waitlist/SKILL.md
# Count troubleshooting rows
TROUBLE_ROWS=$(grep -c "^|.*|.*|.*|$" .agents/skills/gmail-waitlist/SKILL.md 2>/dev/null || echo 0)
if [[ "$TROUBLE_ROWS" -ge 8 ]]; then
  echo "  ✓ Troubleshooting table has ≥8 rows ($TROUBLE_ROWS found)"
  PASS=$((PASS + 1))
else
  echo "  ✗ Troubleshooting table has <8 rows ($TROUBLE_ROWS found)"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "[Content: openai.yaml]"
check_grep "display_name exists" "display_name" .agents/skills/gmail-waitlist/agents/openai.yaml
check_grep "short_description exists" "short_description" .agents/skills/gmail-waitlist/agents/openai.yaml
check_grep "default_prompt contains \$gmail-waitlist" '\$gmail-waitlist' .agents/skills/gmail-waitlist/agents/openai.yaml
check_grep "allow_implicit_invocation: true" "allow_implicit_invocation: true" .agents/skills/gmail-waitlist/agents/openai.yaml

echo ""
echo "[Consistency]"
if diff -q .agents/skills/gmail-waitlist/SKILL.md gmail-waitlist/skills/gmail-waitlist/SKILL.md > /dev/null 2>&1; then
  echo "  ✓ SKILL.md consistent between .agents/ and gmail-waitlist/"
  PASS=$((PASS + 1))
else
  echo "  ✗ SKILL.md differs between .agents/ and gmail-waitlist/"
  FAIL=$((FAIL + 1))
fi

REF_MATCH=true
for f in .agents/skills/gmail-waitlist/references/*.md; do
  fname=$(basename "$f")
  if ! diff -q "$f" "gmail-waitlist/skills/gmail-waitlist/references/$fname" > /dev/null 2>&1; then
    REF_MATCH=false
    break
  fi
done
if $REF_MATCH; then
  echo "  ✓ references/ consistent between .agents/ and gmail-waitlist/"
  PASS=$((PASS + 1))
else
  echo "  ✗ references/ differs between .agents/ and gmail-waitlist/"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "[Safety]"
# Check for hardcoded personal emails (excluding placeholders and documentation mentions)
if grep -rn '@gmail.com' .agents/skills/gmail-waitlist/ \
  | grep -v 'YOUR_EMAIL@gmail.com' \
  | grep -v 'your-email@gmail.com' \
  | grep -v '@example.com' \
  | grep -v 'user@example.com' \
  | grep -v 'for `@gmail.com`' \
  | grep -q '@gmail.com'; then
  echo "  ✗ Hardcoded personal email found in .agents/"
  FAIL=$((FAIL + 1))
else
  echo "  ✓ No hardcoded personal emails"
  PASS=$((PASS + 1))
fi
# Check for hardcoded secrets (exclude doc examples like ya29.a0AfH6SM...)
if grep -rE '(AIza[a-zA-Z0-9_-]{30,}|ya29\.[a-zA-Z0-9_-]{20,}[^.]|1//[a-zA-Z0-9_-]{20,}|sk-[a-zA-Z0-9]{20,})' .agents/skills/gmail-waitlist/ | grep -qv '\.\.\.'; then
  echo "  ✗ Hardcoded secrets/tokens found"
  FAIL=$((FAIL + 1))
else
  echo "  ✓ No hardcoded secrets/tokens"
  PASS=$((PASS + 1))
fi

echo ""
echo "[Universal]"
check "AGENTS.md exists at root" test -f AGENTS.md
check_grep "README.md mentions Claude Code" "Claude Code" README.md
check_grep "README.md mentions Codex" "Codex" README.md
check_grep "README.md mentions Cursor" "Cursor" README.md
check_grep "README.md mentions Copilot" "Copilot" README.md

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
echo "================================"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
