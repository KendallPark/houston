class ApplicationController < ActionController::Base
  include FreightTrain
  include UrlHelper
  protect_from_forgery
  
  
  
  rescue_from CanCan::AccessDenied do |exception|
    if current_user
      if request.xhr?
        render text: exception.message, status: :unauthorized
      else
        redirect_url = request.referrer.blank? ? root_url : :back
        redirect_to redirect_url, :alert => exception.message
      end
    else
      session["user.return_to"] = request.url
      require_login
    end
  end
  
  rescue_from UserCredentials::MissingCredentials do
    head 401, "X-Credentials" => "Missing Credentials"
  end
  
  rescue_from UserCredentials::InvalidCredentials do
    head 401, "X-Credentials" => "Invalid Credentials"
  end
  
  rescue_from UserCredentials::InsufficientPermissions do |exception|
    render text: exception.message, status: 401
  end
  
  
  
  def require_login
    redirect_to new_user_session_path
  end
  
  
  
  def after_sign_in_path_for(user)
    path = session["user_redirect_to"] || stored_location_for(user) || root_path
    path = root_path if path =~ /\/users\/(sign_in|password)/
    path
  end
  
  
  
  def revision
    expire_revision!
    return_or_cache_revision!
  end
  
  def expire_revision!
    if session[:revision_expiration].blank? || session[:revision_expiration] < Time.now.utc
      session[:revision] = nil
      Rails.logger.info "[revision] expiring"
    end
  end
  
  def return_or_cache_revision!
    session[:revision] || read_revision.tap do |sha|
      session[:revision] = sha
      session[:revision_expiration] = 3.minutes.from_now
      Rails.logger.info "[revision] sha: #{sha[0..8]}, expiration: #{session[:revision_expiration]}"
    end
  end
  
  def read_revision
    revision_path = Rails.root.join("REVISION")
    File.exists?(revision_path) ? File.read(revision_path).chomp : ""
  end
  
  
  
  def api_authenticate!
    allow_params_authentication!
    authenticate_or_request_with_http_basic do |username, password|
      params["user"] ||= {}
      params["user"].merge!(email: username, password: password)
      user = warden.authenticate(scope: :user)
      if user
        sign_in(:user, user)
      else
        head :unauthorized
      end
    end
  end
  
  
  
  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  
  
end
