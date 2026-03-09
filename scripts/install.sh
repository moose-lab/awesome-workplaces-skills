#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_NAME="gmail-waitlist"
CANONICAL_DIR="$REPO_DIR/.agents/skills/$SKILL_NAME"

usage() {
  echo "Usage: $0 <agent>"
  echo ""
  echo "Agents:"
  echo "  codex     Install to ~/.agents/skills/ (OpenAI Codex)"
  echo "  cursor    Install to ~/.cursor/skills/ (Cursor)"
  echo "  copilot   Generate AGENTS.md in current directory (GitHub Copilot / Gemini)"
  echo "  claude    Print Claude Code plugin install command"
  echo "  all       Install to all detected agents"
  exit 1
}

install_codex() {
  local target="$HOME/.agents/skills/$SKILL_NAME"
  echo "Installing $SKILL_NAME for Codex → $target"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  cp -r "$CANONICAL_DIR" "$target"
  echo "✓ Codex skill installed. Use \$gmail-waitlist or ask naturally."
}

install_cursor() {
  local target="$HOME/.cursor/skills/$SKILL_NAME"
  echo "Installing $SKILL_NAME for Cursor → $target"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  cp -r "$CANONICAL_DIR" "$target"
  echo "✓ Cursor skill installed. Use /gmail-waitlist or ask naturally."
}

install_copilot() {
  local agents_file="$PWD/AGENTS.md"
  local marker="<!-- skill:$SKILL_NAME -->"

  if [[ -f "$agents_file" ]] && grep -q "$marker" "$agents_file"; then
    echo "✓ AGENTS.md already references $SKILL_NAME — skipping."
    return
  fi

  echo "Generating AGENTS.md reference in $PWD"

  local skill_content
  skill_content=$(sed '1,/^---$/{ /^---$/!d; /^---$/d; }' "$CANONICAL_DIR/SKILL.md" | sed '1,/^---$/d')

  cat >> "$agents_file" <<EOF

$marker
## Skill: Gmail Waitlist

$skill_content
<!-- /skill:$SKILL_NAME -->
EOF

  echo "✓ AGENTS.md updated with $SKILL_NAME reference."
  echo "  GitHub Copilot and Gemini Code Assist will read this automatically."
}

install_claude() {
  echo "Claude Code installation:"
  echo ""
  echo "  claude plugin add github:moose-lab/awesome-workplaces-skills"
  echo ""
  echo "Or for local development:"
  echo ""
  echo "  claude --plugin-dir $REPO_DIR/gmail-waitlist"
}

install_all() {
  echo "=== Installing to all detected agents ==="
  echo ""
  install_codex
  echo ""
  install_cursor
  echo ""
  install_copilot
  echo ""
  install_claude
  echo ""
  echo "=== Done ==="
}

if [[ $# -lt 1 ]]; then
  usage
fi

case "$1" in
  codex)   install_codex ;;
  cursor)  install_cursor ;;
  copilot) install_copilot ;;
  claude)  install_claude ;;
  all)     install_all ;;
  *)       echo "Unknown agent: $1"; usage ;;
esac
