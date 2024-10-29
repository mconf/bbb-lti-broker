class CustomAuthorizationsController < Doorkeeper::AuthorizationsController
  prepend_before_action :redirect_uri_validation, only: [:new]

  def redirect_uri_validation
    uri = URI.parse(params[:redirect_uri])
    Rails.logger.info "[Redirect URI validation] redirect_uri=#{uri}"
    if uri.scheme.to_s.downcase == 'javascript'
      Rails.logger.error "[Redirect URI validation] Invalid 'javascript' redirect_uri scheme"
      render_error
    else
      rooms_uri = URI.parse(Rails.application.config.app_rooms_url)
      unless uri.host.eql?(rooms_uri.host)
        Rails.logger.error "[Redirect URI validation] Invalid redirect_uri host (is not equal to rooms_uri host), " \
                          "rooms_uri_host=#{rooms_uri.host} redirect_uri_host=#{uri.host}"
        render_error
      end
    end
  end

  private

  def render_error
    status = 401
    @error = {
      key: t("error.redirect_uri.code"),
      message: t("error.redirect_uri.message"),
      suggestion: t("error.redirect_uri.suggestion"),
      code: status,
      status: status,
    }

    respond_to do |format|
      format.html { render('errors/index', status: status, layout: false) }
      format.json { render(json: { error: @error[:message] }, status: status) }
      format.all  { render('errors/index', status: status, content_type: 'text/html') }
    end
  end
end
