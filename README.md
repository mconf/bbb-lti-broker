# bbb-lti-broker

The entry point of the LTI integrations of Elos and ConferênciaWeb. It receives the
launches sent by an LMS (e.g. Moodle, Brightspace), validates the client's credential
and hands the user over to the LTI app registered for that launch, such as
[bbb-app-rooms](https://github.com/mconf/bbb-app-rooms).

The same image also runs as the LTI admin dashboard (`/dash`), where client
credentials and per-client app configs are managed. It is a fork of the BigBlueButton
LTI broker and still close to it.

For architecture, conventions and pitfalls, see [AGENTS.md](AGENTS.md).

## Requirements

- Docker and Docker Compose
- To test a full launch: an LMS and an LTI app (e.g. bbb-app-rooms) reachable by the
  broker

## Running locally

```bash
make install   # creates .env from dotenv if missing, builds the dev image
make run       # app + Postgres + Redis on http://localhost:3000/<RELATIVE_URL_ROOT>
```

Review `.env` after `make install` (`dotenv` documents the variables), and add
`ADMIN_KEY` and `ADMIN_PASSWORD`, the dashboard credentials. `scripts/start.sh`
creates or migrates the database on boot. Run `make install` again whenever the
`Gemfile` changes. Background jobs need the Resque worker and scheduler:
`docker compose up broker_worker broker_scheduler`.

Clients and apps are managed in the dashboard (`/dash`, HTTP basic auth with
`ADMIN_KEY` / `ADMIN_PASSWORD`) or with rake tasks (`rake -T db`), run inside the
container with `docker compose run --rm app bin/rake ...`. For example, to register
bbb-app-rooms with the key and secret it uses to call the broker (the second argument
is the app's OAuth2 callback URL, from which the broker also derives where it sends
the launches):

```bash
bin/rake "db:apps:add[rooms,https://<host>/rooms/auth/bbbltibroker/callback,<key>,<secret>]"
```

## Linking an LMS

URLs below assume `RELATIVE_URL_ROOT=lti` and an app named `rooms`.

### LTI 1.0/1.1

The LMS needs the tool URL `https://<broker host>/lti/rooms/messages/blti` and a
consumer key and secret, created as a Tool in the dashboard or with
`bin/rake "db:keys:add[key,secret,tenant]"`.

### LTI 1.3

Register the platform at `https://<broker host>/lti/registration/list` (HTTP basic
auth with `ADMIN_KEY` / `ADMIN_PASSWORD`) or with `bin/rake "db:registration:new"`.
1.3 Tools created directly in the dashboard have no registration and are skipped. The
LMS needs:

| Field | Value |
|---|---|
| Tool URL | `https://<broker host>/lti/rooms/messages/oblti` |
| Initiate login URL | `https://<broker host>/lti/rooms/auth/login` |
| Redirection URIs | `https://<broker host>/lti/rooms/messages/oblti` and `.../messages/deep-link` |
| Client ID, public key | Shown by the registration |

The key set, auth token and auth login URLs come from the LMS after it registers the
tool.

## Tests and lint

The same checks the CI runs (`.github/workflows/ci.yml`):

```bash
make lint      # RuboCop + Brakeman
make format    # RuboCop safe auto-corrections
make test      # prepares the test database and runs RSpec and Minitest
```

All targets run inside Docker Compose (`make help` lists them). To run on the host,
empty the wrapper: `make lint RUN=`, `make test RUN_TEST=`. On the host, set
`DATABASE_URL` to a test database and leave `RELATIVE_URL_ROOT` empty first, as the
CI `test` job does.

## Build

```bash
make build     # tagged bbb-lti-broker:local
```

Releases and deployment: see [AGENTS.md](AGENTS.md#deployment).

## License

See [LICENSE](LICENSE).
