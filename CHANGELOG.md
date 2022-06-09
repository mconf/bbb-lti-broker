# Change Log

## [Unreleased]
<!-- Compare -->
[#Unreleased]: https://github.com/mconf/bbb-lti-broker/compare/master-elos...v0.5.0

## 0.5.0 - 2022-06-09
### Migration notes
- New `resque`, `resque-scheduler`, `active_scheduler` and `prometheus_exporter` gems. Run `bundle install`.
- The `PUMA_WORKERS` environment variable needs to be set to 1, otherwise the
  `prometheus_exporter` won't work.
- The `MCONF_SERVE_RESQUE_INTERFACE` environment variable needs to be set to `true` to render the 
  resque interface.
### Added
* [LTI-46] | Workers for remove old `app_launches` and `lti_launches` in background.
  - PRs: [#8]
* [LTI-84] | `prometheus_exporter` gem to collect information from the Rails application and expose them
  in a format that Prometheus can read.
  - PRs: [#10]
* [LTI-116] | Move `/resque` to `/lti` scope, add `MCONF_SERVE_RESQUE_INTERFACE` environment variable to control the rendering of the resque interface. Add loops on workers to remove more items at a time.
  - PRs: [#11]

<!-- Cards -->
[LTI-46]: https://www.notion.so/Mudar-a-l-gica-de-remo-o-de-itens-antigos-para-ser-em-background-workers-5b88b9304c0e4c44b93f283e6fcd292e
[LTI-84]: https://www.notion.so/Exporter-de-m-tricas-para-o-prometheus-no-LTI-68a2436959804efbb7d14b9705018dbe
[LTI-116]: https://www.notion.so/mconf/Melhorias-no-workers-da-v0-9-0-e-v0-5-0-do-LTI-9aa0b6f0d8cb4cc283ebe391ef409bb1

<!-- PRs -->
[#8]: https://github.com/mconf/bbb-lti-broker/pull/8
[#10]: https://github.com/mconf/bbb-lti-broker/pull/10
[#11]: https://github.com/mconf/bbb-lti-broker/pull/11

<!-- Compare -->
[0.5.0]: https://github.com/mconf/bbb-lti-broker/compare/v0.4.1...v0.5.0

## 0.4.1 - 2022-01-28
### Added
* Remove translation of user roles from `Portal COC`.
  - PRs: [#9]

<!-- PRs -->
[#9]: https://github.com/mconf/bbb-lti-broker/pull/9

<!-- Compare -->
[0.4.1]: https://github.com/mconf/bbb-lti-broker/compare/v0.4.0...v0.4.1

## 0.4.0 - 2022-01-21
### Added
- Added integration with `Portal COC`, using passport `API`.
### Cards
* [LTI-101] | Portal COC
  - Commits: [#54baf4]

<!-- Cards -->
[LTI-101]: https://www.notion.so/mconf/Portal-Gerenciamento-bccb3a3fa75c40f38ead425739d13bb7?p=9ac57ab16aa64130a0ac274241c873ce

<!-- Commits -->
[#54baf4]: https://github.com/mconf/bbb-lti-broker/commit/54baf4d0b7ec0750b7615483d6ec0f69e67651bd

## 0.3.1 - 2021-08-31

* [LTI-79] The `/health` routes have been added to application root
* [LTI-79] Added default lib, to validate and test environment variables: `SERVE_APPLICATION`
  and `SERVE_RAILS_ADMIN`
* [LTI-79] If the application is only serving Rails Admin, the root route is `/dash`


## 0.3.0 Elos - 2021-07-27

* [LTI-29] Added Rails Admin and variables for serve application and/or Rails Admin.
* [LTI-45] Improved the `AppLaunches` deletion log and added an index in the
  `expiration_time` field.

Migration notes:

* New environment variables `SERVE_APPLICATION`, `SERVE_RAILS_ADMIN`
  `AUTHENTICATION_RAILS_ADMIN`, `ADMIN_KEY` and `ADMIN_PASSWORD`, it is necessary to
  configure as needed for use application and/or rails admin.
* Created a migration to add index on `expires_at` field for better performance in
  deleting old `AppLaunches`.



## 0.2.0 Elos - 2021-06-26

* [LTI-51] Update rails to fix missing mimemagic version.
* [LTI-44] Automatically remove old `AppLaunches`. Removes all launches older than
  `LAUNCH_DAYS_TO_DELETE` days. Defaults to 15.

Migration notes:

* New environment variable `LAUNCH_DAYS_TO_DELETE` to decide how old launches have to be
  to be automatically removed. Defaults to 15 (will remove all launches from 15 or more
  days ago).


## 0.1.0 Elos - 2020-08-16

* Serve assets in production if `RAILS_SERVE_STATIC_FILES` is set and allow the configuration
  of a CDN with `ASSET_HOST`.
* Review/fix options in xml_config: The XML will always add canvas extensions; Better URLs
  for icons; Better strings for Elos.
* Update `rails_lti2_provider` to log errors if the gem throws an exception.
* Add option to configure the text of menu extensions in the config XML. Using `placement_text=`
  in the `xml_config` URL allows callers to customize the text that will be used to trigger the
  LTI in Canvas.
* Add specific flags to control SameSite and Secure on cookies. The default is still `SameSite=None`
  and `Secure`.


## 0.0.8 Elos - 2020-07-19

* Add several indexes to the database to speed up queries.
* Configure the session cookie with SameSite=None and Secure to reduce issues when opening
  the application in an iframe.
