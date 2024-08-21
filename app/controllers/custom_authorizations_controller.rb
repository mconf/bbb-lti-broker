class CustomAuthorizationsController < Doorkeeper::AuthorizationsController
  before_action :redirect_uri_validation, only: [:new]

  def redirect_uri_validation
    uri = URI.parse(params[:redirect_uri])
    if uri.scheme.to_s.downcase == 'javascript'
      render_error
    else
      rooms_uri = URI.parse(Rails.application.config.app_rooms_url)
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
