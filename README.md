# Awesome Workplaces Skills

A curated collection of agent skills for common product development workflows, with support for both Claude Code plugins and Codex skills.

## Available Skills

### gmail-waitlist

Add a zero-cost email waitlist to any landing page using Gmail API, GCP OAuth, and Vercel serverless functions. No database, no third-party email service — signups land directly in your Gmail inbox.

**Stack:** GCP OAuth + gws CLI + Vercel Serverless + Gmail API

## Installation

### As a Claude Code plugin

```bash
claude plugin add github:moose-lab/awesome-workplaces-skills
```

### As a local plugin (development)

```bash
git clone https://github.com/moose-lab/awesome-workplaces-skills.git
claude --plugin-dir ./awesome-workplaces-skills/gmail-waitlist
```

### As a Codex skill (local)

```bash
git clone https://github.com/moose-lab/awesome-workplaces-skills.git
mkdir -p ~/.codex/skills
ln -sfn "$(pwd)/awesome-workplaces-skills/gmail-waitlist/skills/gmail-waitlist" ~/.codex/skills/gmail-waitlist
```

The Codex entry point lives at `gmail-waitlist/skills/gmail-waitlist/agents/openai.yaml`, so the skill can appear in the Codex skills UI and provide a one-click default prompt.

## Triggering a Skill

Once installed, skills activate automatically based on context. Try:

- "Add a waitlist to my landing page"
- "Create an email signup form"
- "Implement early access email notification"

For explicit Codex invocation, call the skill directly with:

- `$gmail-waitlist Add a zero-cost email waitlist with Gmail notifications to my landing page`

If your Codex client shows skill chips, the `Gmail Waitlist` chip uses the same default prompt for one-click invocation.

## Contributing

1. Fork the repository
2. Create a new skill directory under the appropriate plugin
3. Follow the skill structure: `skills/skill-name/SKILL.md` + supporting files
4. Submit a pull request

## License

MIT
