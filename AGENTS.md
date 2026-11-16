# AGENTS.md

AI development guidelines for bbb-lti-broker.

## Project Overview

The entry point of the LTI integrations of Elos and ConferênciaWeb. It receives the
launches sent by the institution's LMS (LTI 1.0/1.1 and 1.3), validates the client's
credential and hands the user over to the registered LTI app: `rooms`
([bbb-app-rooms](https://github.com/mconf/bbb-app-rooms), the default), `worka` or
`eduplay`.

The same image also runs as the LTI admin dashboard (RailsAdmin at `/dash`, with
`SERVE_APPLICATION=false`): it is where client credentials and the per-client
configs of every app are created and edited.

It is a fork of the upstream BigBlueButton broker and still close to it (unlike
bbb-app-rooms, which diverged). The LTI models come from our fork of
`rails_lti2_provider` (`mconf/rails_lti2_provider`, branch `elos`, in the `Gemfile`).

Non-obvious parts of the tree:

```text
app/controllers/concerns/   # Most of the LTI logic (OAuth/OIDC validation, app lookup, services)
lib/bbb_lti_broker/         # Message normalization sent to the apps (helpers.rb)
lib/tasks/                  # rake db:apps|keys|tenants|registration:* to manage clients
config/initializers/rails_lti2_provider.rb  # Extensions to the gem's Tool/Tenant/LtiLaunch
config/initializers/rails_admin.rb          # The dashboard
test/                       # Minitest suite, run by CI alongside spec/
```

## Development Setup

Use the Makefile (`make help`). Targets run inside Docker Compose by default; to run
on the host, empty the wrapper (`make lint RUN=`, `make test RUN_TEST=`).

```bash
make install   # create .env from dotenv if missing, build the dev image
make run       # app + Postgres + Redis on port 3000; scripts/start.sh migrates on boot
```

`.env` is not committed; `dotenv` is the documented template. Workers:
`docker compose up broker_worker broker_scheduler`.

## Verifying Changes

Run the same checks CI runs (`.github/workflows/ci.yml`):

```bash
make lint      # rubocop -l (lint cops only, as in CI) + brakeman
make test      # db:test:prepare + RSpec + Minitest
```

- There are two suites, `spec/` (RSpec) and `test/` (Minitest), and CI runs both.
- Never run the tests with the app's `DATABASE_URL`: in the test env the URL wins over
  `config/database.yml`, so `db:test:prepare` would wipe the development database.
  `make test` swaps the database name; on the host, set it as the CI does.
- `RELATIVE_URL_ROOT` must be empty or unset in tests: the routes are not scoped by it
  but the path helpers prepend it, so any value makes integration requests 404. The
  `.env` sets it, and dotenv loads `.env` in the test env too.
- With eager loading on (production, and tests with `CI=true`, as in CI), `ADMIN_KEY`
  and `ADMIN_PASSWORD` must be set at boot: several controllers pass them to
  `http_basic_authenticate_with` in the class body, which rejects `nil`. They are not
  in `dotenv`.
- The dev image is built without the test gems (`webmock`, minitest helpers);
  `make test` installs them into the bundle volume.
- Triaged Brakeman findings live in `config/brakeman.ignore`, each with a note.

## Code Style

- Follow `.rubocop.yml`.
- Configuration: read env vars in `config/application.rb` (or an initializer) with
  `Mconf::Env.fetch` / `fetch_boolean` / `fetch_int`, and document new variables in
  `dotenv`.
- Commit messages follow Conventional Commits (`feat:`, `fix:`, `test:`, `chore:` …).

## Architecture

### Clients and apps

- `RailsLti2Provider::Tenant`: a client (`uid`, `institution_guid`).
- `RailsLti2Provider::Tool`: a credential of a tenant. LTI 1.0/1.1 uses `uuid` (consumer
  key) and `shared_secret`; LTI 1.3 keeps the registration (client id, platform URLs,
  key set) as JSON in `tool_settings`, with keys in `RsaKeyPair`.
- Per-tool configs for each app: `RoomsAppConfig`, `WorkaAppConfig`,
  `EduplayAppConfig`, `BbbConfig` (dedicated BBB server).
- `Doorkeeper::Application`: each downstream app (`rooms`, `worka`, `eduplay`), with
  the OAuth2 credentials it uses to call back the broker.

### Launch flow

1. The LMS posts to `/:app/messages/blti` (1.0/1.1, OAuth-signed) or goes through the
   OIDC login (`/:app/auth/login`) and posts to `/:app/messages/oblti` (1.3, JWT).
2. `MessageController` validates the message, stores it as an `LtiLaunch` (keyed by
   the nonce) and, in `add_custom_params_to_launch_message`, merges the tool's app
   configs into `custom_params`.
3. `AppsController#launch` redirects to the app with the `launch_nonce`. The app URL is
   derived from the Doorkeeper app's `redirect_uri` (`lti_app_url`): the last segments
   of the callback path are swapped for `/launch`.
4. The app authenticates with OAuth2 (Doorkeeper), fetches the launch with
   `GET /api/v1/sessions/:token` and invalidates it with `.../invalidate`.

### Contract with the apps

- Every `RoomsAppConfig` column is sent to rooms in `custom_params`
  (`Tool#rooms_app_configs_for_launch`): `moodle_*` and `brightspace_*` columns are
  grouped into nested hashes (sent only when the integration is enabled), `BbbConfig`
  goes as `bbb`, plus the tenant's `institution_guid`. The same applies to worka and
  eduplay with their own configs.
- A new per-client flag needs: a migration here (RailsAdmin shows it automatically,
  add a label and help in `rails_admin.rb`) and its mapping in the app (rooms:
  `setup_consumer_configs`). Deploy the broker before the app.
- `standarized_message` (`lib/bbb_lti_broker/helpers.rb`) maps LTI 1.3 claims to the
  1.1 parameter names, so the apps read both versions the same way.

### Cache and session

- `Rails.cache` holds the LTI 1.3 OIDC nonces and launch data between requests. In
  production it is Redis when `REDIS_URL` is set, otherwise a per-pod `file_store`,
  which breaks launches with more than one pod. In tests it is `:null_store`.
- Sessions are stored in the database (`active_record_store`); the cookie is
  `SameSite=None`, `Secure` and partitioned, since launches happen inside the LMS
  iframe.

## Common Pitfalls

- `RELATIVE_URL_ROOT` is applied in `config.ru` (`map`), not in the routes; use path
  helpers.
- Changing a Doorkeeper app's `redirect_uri` changes where launches are sent.
- `DEVELOPER_MODE_ENABLED` exposes the OAuth apps UI and logs every request's
  parameters; never enable it in production.
- In Kubernetes, migrations do not run on boot: the deployment overrides the command
  with `rails s`, and `db:migrate` runs as a separate Job in the infra repos. The old
  pods keep serving while it runs, so keep migrations backward compatible (see
  `development/database-migrations.md` in mpedia).
- Never commit credentials or real `.env` values.

## Deployment

- The version lives in `config/application.rb` (`VERSION`); releases are commits named
  `Version X.Y.Z` plus a `vX.Y.Z` tag.
- Pushing a `v*.*.*` tag builds and pushes the image to Harbor
  (`.github/workflows/build.yml`).
- Deployment is not done from this repo: the Kubernetes manifests (web, workers,
  scheduler, dashboard, and the migrate, seed and rollback jobs) live in the infra
  repositories, one per environment.

## Resources

- Catalog entry: <https://github.com/mconf/mpedia/blob/main/architecture/components/portal-bbb-lti-broker.yaml>
- Mconf development standards: <https://github.com/mconf/mpedia/tree/main/development>
  (loaded automatically by the `mpedia-dev` agent skill — no per-project setup needed)
