# Awesome Workplaces Skills

A curated collection of Claude Code skills for common product development workflows.

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

## Triggering a Skill

Once installed, skills activate automatically based on context. Try:

- "Add a waitlist to my landing page"
- "Create an email signup form"
- "Implement early access email notification"

## Contributing

1. Fork the repository
2. Create a new skill directory under the appropriate plugin
3. Follow the skill structure: `skills/skill-name/SKILL.md` + supporting files
4. Submit a pull request

## License

MIT
