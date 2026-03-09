# Awesome Workplaces Skills — Contributor Guide

This repository is a multi-agent skill marketplace. Each skill is a self-contained module that can be discovered and executed by Claude Code, OpenAI Codex, Cursor, and other AI coding agents.

## Repository Structure

- **Canonical skill source:** `.agents/skills/<skill-name>/` — edit files here
- **Claude Code plugin copy:** `<skill-name>/skills/<skill-name>/` — synced from canonical source
- **Sync script:** `scripts/sync-skills.sh` — keeps Claude Code copy in sync
- **Validation:** `scripts/validate-all-agents.sh` — checks structure, content, and consistency

## Adding a New Skill

1. Create `.agents/skills/<skill-name>/SKILL.md` with frontmatter (`name`, `description`)
2. Add `references/`, `examples/`, `scripts/` subdirectories as needed
3. Create `.agents/skills/<skill-name>/agents/openai.yaml` for Codex UI metadata
4. Create the Claude Code plugin directory: `<skill-name>/.claude-plugin/plugin.json`
5. Run `bash scripts/sync-skills.sh` to copy to Claude Code plugin directory
6. Register the plugin in `.claude-plugin/marketplace.json`
7. Run `bash scripts/validate-all-agents.sh` to verify everything passes

## Available Skills

| Skill | Description |
|-------|-------------|
| `gmail-waitlist` | Zero-cost Gmail-powered email waitlist for landing pages |
