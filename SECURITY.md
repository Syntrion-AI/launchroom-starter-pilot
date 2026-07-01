# Security

LaunchRoom Starter must never request or store secret values in chat or repository files.

Blocked without a separate approved path:

- API keys, tokens, passwords, private keys, OAuth values, and connection strings in chat.
- Copying `.env`, `auth.json`, `state.db`, OAuth stores, or session stores between profiles.
- Cloudflare, Hetzner, n8n, provider, billing, production, or public release mutations.

Allowed after user choice:

- Non-secret profile configuration.
- Workspace creation inside the selected path.
- Workspace-local reports and instruction files.
- Software recommendations without installation.
