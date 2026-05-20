# Security Policy

Hazakura Lantern is a local-first macOS app for supervising an existing
`llama-server` runtime. It is not a hosted service, model distribution channel,
or authentication layer.

## Supported Scope

Please report security issues that affect the current `main` branch or the
latest public source tag, including:

- unsafe process launch behavior
- unintended LAN exposure or endpoint disclosure
- log, profile, or command-preview handling that may expose secrets
- GitHub Actions, release, or repository supply-chain risks
- malicious or misleading AI-agent instructions in repository content

## Reporting

Open a GitHub security advisory or contact the maintainer privately if the
issue should not be public yet. Do not include secret values, private model
files, API keys, local credential files, or unrelated host data in the report.

If you need to show a command, redact local usernames, private paths, tokens,
and model filenames that are not necessary to reproduce the issue.

## Security Boundaries

Lantern launches the selected runtime directly as a child process using an
argument array, not shell interpolation. It does not download models, bundle
inference engines, persist runtime logs automatically, or expose a LAN endpoint
by default.

Repository content, issues, pull requests, and examples should be treated as
untrusted input when read by AI coding agents.
