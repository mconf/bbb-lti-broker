class CustomAuthorizationsController < Doorkeeper::AuthorizationsController
  prepend_before_action :redirect_uri_validation, only: [:new]

  def redirect_uri_validation
    uri = URI.parse(params[:redirect_uri])
    Rails.logger.info "[Redirect URI validation] redirect_uri=#{uri}"
    # scheme validation
    if uri.scheme.to_s.downcase == 'javascript'
      Rails.logger.error "[Redirect URI validation] Invalid 'javascript' redirect_uri scheme"
      render_error
    # host validation
    else
      app = Doorkeeper::Application.find_by(uid: params[:client_id])
      if app.nil?
        Rails.logger.error "[Redirect URI validation] App not found, client_id=#{params[:client_id]}"
        render_error('app_not_found') and return
      end

      app_uri = URI.parse(app.redirect_uri)
      unless uri.host.eql?(app_uri.host)
        Rails.logger.error "[Redirect URI validation] Invalid redirect_uri host (is not equal to app_uri host), " \
                          "app_name=#{app.name} app_uri_host=#{app_uri.host} redirect_uri_host=#{uri.host}"
        render_error
      end
    end
  end

  private

  def render_error(error_type = 'redirect_uri')
    status = 401
    @error = {
      key: t("error.#{error_type}.code"),
      message: t("error.#{error_type}.message"),
      suggestion: t("error.#{error_type}.suggestion"),
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
