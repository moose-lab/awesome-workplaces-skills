#!/usr/bin/env bash

set -euo pipefail

skill_dir="gmail-waitlist/skills/gmail-waitlist"
skill_md="$skill_dir/SKILL.md"
openai_yaml="$skill_dir/agents/openai.yaml"

if [[ ! -f "$skill_md" ]]; then
  echo "Missing skill definition: $skill_md" >&2
  exit 1
fi

if [[ ! -f "$openai_yaml" ]]; then
  echo "Missing Codex metadata: $openai_yaml" >&2
  exit 1
fi

rg -q '^name: gmail-waitlist$' "$skill_md"
rg -q 'display_name: "Gmail Waitlist"' "$openai_yaml"
rg -q 'short_description: "Add a zero-cost Gmail-powered email waitlist"' "$openai_yaml"
rg -q 'default_prompt: "Use \$gmail-waitlist' "$openai_yaml"
rg -q 'Codex' README.md
rg -q '\$gmail-waitlist' README.md

echo "Codex skill support validation passed."
