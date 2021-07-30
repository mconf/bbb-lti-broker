# Change Log

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
