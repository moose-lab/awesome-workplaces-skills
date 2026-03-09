#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

ERRORS=0

sync_skill() {
  local skill_name="$1"
  local src="$REPO_DIR/.agents/skills/$skill_name"
  local dst="$REPO_DIR/$skill_name/skills/$skill_name"

  if [[ ! -f "$src/SKILL.md" ]]; then
    echo "✗ $skill_name: SKILL.md not found in canonical source" >&2
    ERRORS=$((ERRORS + 1))
    return
  fi

  echo "Syncing: $skill_name"

  # SKILL.md
  mkdir -p "$dst"
  cp "$src/SKILL.md" "$dst/SKILL.md"
  echo "  ✓ SKILL.md"

  # references/ → under skills/ (same level as SKILL.md)
  if [[ -d "$src/references" ]]; then
    mkdir -p "$dst/references"
    cp "$src/references/"* "$dst/references/"
    echo "  ✓ references/"
  fi

  # examples/ → under skills/ (same level as SKILL.md for correct relative paths)
  if [[ -d "$src/examples" ]]; then
    mkdir -p "$dst/examples"
    cp "$src/examples/"* "$dst/examples/"
    echo "  ✓ examples/"
  fi

  # scripts/ → under skills/ (same level as SKILL.md for correct relative paths)
  if [[ -d "$src/scripts" ]]; then
    mkdir -p "$dst/scripts"
    cp "$src/scripts/"* "$dst/scripts/"
    echo "  ✓ scripts/"
  fi

  # Verify consistency
  echo ""
  echo "  Verifying consistency..."

  local files_to_check=("SKILL.md")

  if [[ -d "$src/references" ]]; then
    for f in "$src/references/"*; do
      files_to_check+=("references/$(basename "$f")")
    done
  fi

  if [[ -d "$src/examples" ]]; then
    for f in "$src/examples/"*; do
      files_to_check+=("examples/$(basename "$f")")
    done
  fi

  if [[ -d "$src/scripts" ]]; then
    for f in "$src/scripts/"*; do
      files_to_check+=("scripts/$(basename "$f")")
    done
  fi

  for rel in "${files_to_check[@]}"; do
    if diff -q "$src/$rel" "$dst/$rel" > /dev/null 2>&1; then
      echo "  ✓ $rel consistent"
    else
      echo "  ✗ $rel mismatch!" >&2
      ERRORS=$((ERRORS + 1))
    fi
  done
}

# Auto-detect all skills in .agents/skills/
echo "Scanning .agents/skills/ for skills..."
echo ""

SKILL_COUNT=0
for skill_dir in "$REPO_DIR/.agents/skills/"*/; do
  if [[ -d "$skill_dir" ]]; then
    skill_name=$(basename "$skill_dir")
    sync_skill "$skill_name"
    SKILL_COUNT=$((SKILL_COUNT + 1))
    echo ""
  fi
done

if [[ "$SKILL_COUNT" -eq 0 ]]; then
  echo "No skills found in .agents/skills/" >&2
  exit 1
fi

if [[ "$ERRORS" -gt 0 ]]; then
  echo "✗ Sync completed with $ERRORS errors" >&2
  exit 1
fi

echo "✓ All $SKILL_COUNT skill(s) in sync."
