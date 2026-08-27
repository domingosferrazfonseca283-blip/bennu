# Bennu OS

Bennu OS is an intelligent operational platform combining AI agents, automation, cybersecurity, business operations, development and cloud management.

## v0.1 — Foundation

Initial architecture focuses on a safe, modular core:

- Bennu Core API
- Dashboard-ready event model
- Agent registry and permission model
- Security/audit event model
- Plugin architecture specification
- Intelligent terminal specification
- Linux distribution roadmap

## Architecture

```text
bennu/
├── apps/
│   ├── api/              # Core API
│   ├── dashboard/        # Web/Desktop UI
│   └── terminal/         # CLI
├── packages/
│   ├── agents/           # Agent runtime and policies
│   ├── security/         # Security domain
│   ├── automation/       # Workflow engine
│   └── plugins/          # Plugin contracts
├── infra/
│   ├── docker/
│   └── linux/            # Bennu OS image/build assets
├── docs/
└── .github/
```

## Principles

1. Security and explicit authorization before autonomous execution.
2. API-first architecture shared by Linux, Windows, Android and Web clients.
3. Modular agents with scoped tools, budgets and audit trails.
4. Provider-neutral AI gateway supporting local and hosted models.
5. Observable by default: events, metrics, logs and task history.

## Roadmap

- [ ] Core health/status API
- [ ] PostgreSQL persistence
- [ ] Authentication + RBAC + MFA foundation
- [ ] Agent registry
- [ ] Tool permission engine
- [ ] Event bus and audit log
- [ ] Dashboard MVP
- [ ] Security center MVP
- [ ] Bennu terminal
- [ ] Docker deployment
- [ ] Debian-based Bennu OS alpha ISO
- [ ] Android companion
