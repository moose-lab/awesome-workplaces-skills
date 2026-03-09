#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_NAME="gmail-waitlist"
CANONICAL_DIR="$REPO_DIR/.agents/skills/$SKILL_NAME"

if [[ ! -d "$CANONICAL_DIR" ]]; then
  echo "Error: Canonical skill source not found at $CANONICAL_DIR" >&2
  echo "Make sure you have cloned the repository first:" >&2
  echo "  git clone https://github.com/moose-lab/awesome-workplaces-skills.git" >&2
  exit 1
fi

usage() {
  echo "Usage: $0 <agent> [target-dir]"
  echo ""
  echo "Agents:"
  echo "  codex     Copy skill to project .agents/skills/ (OpenAI Codex)"
  echo "  cursor    Copy skill to project .cursor/skills/ (Cursor)"
  echo "  copilot   Generate AGENTS.md in target directory (GitHub Copilot / Gemini)"
  echo "  windsurf  Generate .windsurf/rules/ in target directory (Windsurf)"
  echo "  claude    Print Claude Code plugin install command"
  echo "  all       Install for all agents in target directory"
  echo ""
  echo "  target-dir  Project directory to install into (default: current directory)"
  exit 1
}

install_codex() {
  local project_dir="$1"
  local target="$project_dir/.agents/skills/$SKILL_NAME"
  echo "Installing $SKILL_NAME for Codex → $target"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  cp -r "$CANONICAL_DIR" "$target"
  echo "✓ Codex skill installed. Use \$gmail-waitlist or ask naturally."
}

install_cursor() {
  local project_dir="$1"
  local target="$project_dir/.cursor/skills/$SKILL_NAME"
  echo "Installing $SKILL_NAME for Cursor → $target"
  rm -rf "$target"
  mkdir -p "$(dirname "$target")"
  cp -r "$CANONICAL_DIR" "$target"
  echo "✓ Cursor skill installed. Use /gmail-waitlist or ask naturally."
}

install_copilot() {
  local project_dir="$1"
  local agents_file="$project_dir/AGENTS.md"
  local marker="<!-- skill:$SKILL_NAME -->"

  if [[ -f "$agents_file" ]] && grep -q "$marker" "$agents_file"; then
    echo "✓ AGENTS.md already references $SKILL_NAME — skipping."
    return
  fi

  echo "Generating AGENTS.md reference in $project_dir"

  # Strip YAML frontmatter (compatible with both BSD and GNU sed/awk)
  local skill_content
  skill_content=$(awk 'BEGIN{n=0} /^---$/{n++;next} n>=2{print}' "$CANONICAL_DIR/SKILL.md")

  cat >> "$agents_file" <<EOF

$marker
## Skill: Gmail Waitlist

$skill_content
<!-- /skill:$SKILL_NAME -->
EOF

  echo "✓ AGENTS.md updated with $SKILL_NAME skill content."
  echo "  GitHub Copilot and Gemini Code Assist will read this automatically."
}

install_windsurf() {
  local project_dir="$1"
  local rules_dir="$project_dir/.windsurf/rules"
  local rule_file="$rules_dir/$SKILL_NAME.md"

  if [[ -f "$rule_file" ]]; then
    echo "✓ .windsurf/rules/$SKILL_NAME.md already exists — replacing."
  fi

  mkdir -p "$rules_dir"

  # Strip YAML frontmatter
  local skill_content
  skill_content=$(awk 'BEGIN{n=0} /^---$/{n++;next} n>=2{print}' "$CANONICAL_DIR/SKILL.md")

  cat > "$rule_file" <<EOF
$skill_content
EOF

  echo "✓ Windsurf rule created at $rule_file"
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
  local project_dir="$1"
  echo "=== Installing $SKILL_NAME for all agents ==="
  echo ""
  install_codex "$project_dir"
  echo ""
  install_cursor "$project_dir"
  echo ""
  install_copilot "$project_dir"
  echo ""
  install_windsurf "$project_dir"
  echo ""
  install_claude
  echo ""
  echo "=== Done ==="
}

if [[ $# -lt 1 ]]; then
  usage
fi

AGENT="$1"
TARGET_DIR="${2:-$PWD}"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
  echo "Error: target directory '$2' does not exist" >&2
  exit 1
}

case "$AGENT" in
  codex)    install_codex "$TARGET_DIR" ;;
  cursor)   install_cursor "$TARGET_DIR" ;;
  copilot)  install_copilot "$TARGET_DIR" ;;
  windsurf) install_windsurf "$TARGET_DIR" ;;
  claude)   install_claude ;;
  all)      install_all "$TARGET_DIR" ;;
  *)        echo "Unknown agent: $AGENT"; usage ;;
esac
