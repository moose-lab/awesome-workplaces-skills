# Awesome Workplaces Skills

A curated collection of agent skills for common product development workflows, compatible with Claude Code, OpenAI Codex, Cursor, GitHub Copilot, and more.

## Available Skills

### gmail-waitlist

Add a zero-cost email waitlist to any landing page using Gmail API, GCP OAuth, and Vercel serverless functions. No database, no third-party email service — signups land directly in your Gmail inbox.

**Stack:** GCP OAuth + gws CLI + Vercel Serverless + Gmail API

## Compatibility

| Agent | Install Method | Auto-Discovery |
|-------|---------------|----------------|
| Claude Code | `/plugin marketplace add` | Skill auto-triggers on matching prompts |
| OpenAI Codex | `install.sh codex` or manual copy | `$gmail-waitlist` or implicit invocation |
| Cursor | GitHub import or `install.sh cursor` | `/gmail-waitlist` or implicit invocation |
| GitHub Copilot | `install.sh copilot` → generates AGENTS.md | Reads project AGENTS.md |
| Windsurf | `install.sh windsurf` → generates rules | Reads `.windsurf/rules/` |
| Gemini Code Assist | `install.sh copilot` → generates AGENTS.md | Reads project AGENTS.md |

## Installation

### Claude Code (recommended)

```bash
# From the marketplace
claude plugin add github:moose-lab/awesome-workplaces-skills
```

```bash
# Local development
git clone https://github.com/moose-lab/awesome-workplaces-skills.git
claude --plugin-dir ./awesome-workplaces-skills/gmail-waitlist
```

### OpenAI Codex

```bash
# One-line install
bash <(curl -s https://raw.githubusercontent.com/moose-lab/awesome-workplaces-skills/main/scripts/install.sh) codex

# Or manual
git clone https://github.com/moose-lab/awesome-workplaces-skills.git
cp -r awesome-workplaces-skills/.agents/skills/gmail-waitlist ~/.agents/skills/
```

### Cursor

```bash
# Option A: Native GitHub import (recommended)
# Settings → Skills → Import from GitHub → moose-lab/awesome-workplaces-skills

# Option B: Script install
bash scripts/install.sh cursor
```

### GitHub Copilot / Gemini Code Assist

```bash
# Generates an AGENTS.md in your project that references the skill
bash scripts/install.sh copilot
```

## Triggering a Skill

Once installed, skills activate automatically based on context. Try:

- "Add a waitlist to my landing page"
- "Create an email signup form"
- "Implement early access email notification"
- "Collect emails for my launch"

For explicit Codex invocation: `$gmail-waitlist`

## Contributing

1. Fork the repository
2. Create a skill in `.agents/skills/<skill-name>/` (see `AGENTS.md` for structure)
3. Run `bash scripts/sync-skills.sh && bash scripts/validate-all-agents.sh`
4. Submit a pull request

## License

MIT
