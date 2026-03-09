#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

SKILL_NAME="gmail-waitlist"
SRC="$REPO_DIR/.agents/skills/$SKILL_NAME"
DST="$REPO_DIR/$SKILL_NAME/skills/$SKILL_NAME"

if [[ ! -d "$SRC" ]]; then
  echo "✗ Canonical source not found: $SRC" >&2
  exit 1
fi

echo "Syncing: $SRC → $DST"

# Sync SKILL.md
mkdir -p "$DST"
cp "$SRC/SKILL.md" "$DST/SKILL.md"
echo "  ✓ SKILL.md"

# Sync references/
if [[ -d "$SRC/references" ]]; then
  mkdir -p "$DST/references"
  cp "$SRC/references/"*.md "$DST/references/"
  echo "  ✓ references/"
fi

# Sync examples/ → gmail-waitlist/examples/
if [[ -d "$SRC/examples" ]]; then
  mkdir -p "$REPO_DIR/$SKILL_NAME/examples"
  cp "$SRC/examples/"* "$REPO_DIR/$SKILL_NAME/examples/"
  echo "  ✓ examples/"
fi

# Sync scripts/ → gmail-waitlist/scripts/
if [[ -d "$SRC/scripts" ]]; then
  mkdir -p "$REPO_DIR/$SKILL_NAME/scripts"
  cp "$SRC/scripts/"* "$REPO_DIR/$SKILL_NAME/scripts/"
  echo "  ✓ scripts/"
fi

echo ""
echo "✓ Sync complete. Verifying consistency..."

# Verify SKILL.md match
if diff -q "$SRC/SKILL.md" "$DST/SKILL.md" > /dev/null 2>&1; then
  echo "  ✓ SKILL.md consistent"
else
  echo "  ✗ SKILL.md mismatch!" >&2
  exit 1
fi

# Verify references/ match
if [[ -d "$SRC/references" ]]; then
  for f in "$SRC/references/"*.md; do
    fname=$(basename "$f")
    if diff -q "$f" "$DST/references/$fname" > /dev/null 2>&1; then
      echo "  ✓ references/$fname consistent"
    else
      echo "  ✗ references/$fname mismatch!" >&2
      exit 1
    fi
  done
fi

echo ""
echo "✓ All files in sync."
