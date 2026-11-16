# Self-documenting Makefile: run `make` or `make help` to list the targets.
#
# Commands run inside Docker by default, as the team does. To run them on the host
# (or in CI), empty the wrapper, e.g. `make lint RUN=` or `make test RUN_TEST=`.

.DEFAULT_GOAL := help

COMPOSE ?= docker compose
RUN ?= $(COMPOSE) run --rm --no-deps app

# The specs need their own database. The app's DATABASE_URL points to the
# development one, and in the test env the URL wins over config/database.yml, so the
# test run swaps the database name instead of reusing the URL as is.
TEST_DATABASE_URL ?= $(shell $(COMPOSE) config 2>/dev/null | sed -n 's|^ *DATABASE_URL: \(.*\)/[^/]*$$|\1/bbb_lti_broker_test|p' | head -1)
# - BUNDLE_WITHOUT/BUNDLE_APP_CONFIG: the dev image is built without the test gems
#   (webmock, minitest helpers), and that setting lives in the image's bundle config,
#   which wins over the env; pointing BUNDLE_APP_CONFIG elsewhere lets the run
#   install them into the bundle volume.
# - RELATIVE_URL_ROOT: the routes are not scoped by it but the path helpers prepend
#   it, so the value from .env makes every integration request 404.
RUN_TEST ?= $(COMPOSE) run --rm -e RAILS_ENV=test \
	-e BUNDLE_WITHOUT=doc -e BUNDLE_APP_CONFIG=/tmp/bundle \
	-e RELATIVE_URL_ROOT= -e DATABASE_URL=$(TEST_DATABASE_URL) app

IMAGE ?= bbb-lti-broker:local

.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

.PHONY: install
install: ## Create .env from dotenv (if missing) and build the dev image
	@test -f .env || { cp dotenv .env && echo "Created .env from dotenv; review it before running."; }
	$(COMPOSE) build app

.PHONY: run
run: ## Run the app with Postgres and Redis (port 3000)
	$(COMPOSE) up app

.PHONY: lint
lint: ## Run RuboCop (lint cops, as in CI) and Brakeman
	$(RUN) bundle exec rubocop -l --config .rubocop.yml
	$(RUN) bundle exec brakeman -q --no-pager

.PHONY: format
format: ## Auto-correct RuboCop offenses (safe corrections only)
	$(RUN) bundle exec rubocop -a --config .rubocop.yml

.PHONY: test
test: ## Prepare the test database and run both suites (RSpec and Minitest)
	$(RUN_TEST) sh -c "bundle install --quiet && bin/rails db:test:prepare && bundle exec rspec && bin/rails test"

.PHONY: build
build: ## Build the production image
	docker build -t $(IMAGE) .
