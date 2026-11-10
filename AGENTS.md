# AGENTS.md

LTI broker: receives LTI 1.1 and 1.3 launches from LMSs, validates them and hands them to the apps (rooms, worka, eduplay). Also serves the admin dash (RailsAdmin) at `/dash`.

Placeholder: this repo does not follow the Mconf repository baseline yet (no Makefile, no pre-commit hook). Standards: https://github.com/mconf/mpedia/tree/main/development

## Checks

The same commands CI runs (`.github/workflows/ci.yml`):

```bash
bundle exec rubocop
bundle exec rspec
bin/rails test
bundle exec brakeman -q
```

## Logs never carry credentials

Launches carry credentials: tool shared secrets, BBB secrets, Moodle and Brightspace tokens, OAuth tokens. Logs end up in shared storage, so a credential in a log line is a leaked credential.

- Never interpolate a secret or a token into a log line, nor a hash that may hold one (a tool's config, the message with its `custom_params`). Log ids instead (`tool_id=42`).
- Personal data (names, e-mails) only when needed, e.g. support correlates launches by e-mail. Once logged, the log retention policy takes care of it.
