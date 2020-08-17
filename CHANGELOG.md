# Change Log

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
