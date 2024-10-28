class CustomAuthorizationsController < Doorkeeper::AuthorizationsController
  prepend_before_action :redirect_uri_validation, only: [:new]

  def redirect_uri_validation
    uri = URI.parse(params[:redirect_uri])
    Rails.logger.info "[Redirect URI validation] redirect_uri=#{uri}"
    if uri.scheme.to_s.downcase == 'javascript'
      render_error
    else
      rooms_uri = URI.parse(Rails.application.config.app_rooms_url)
      Rails.logger.info "[Redirect URI validation] rooms_uri=#{rooms_uri} uri_host=#{uri.host} rooms_uri_host=#{rooms_uri.host}"
      render_error unless uri.host.eql?(rooms_uri.host)
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
