class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to '/', alert: t('before_sign_in.session_expired', sign_in_link: sign_in_link)
  end

  private
  def sign_in_link
    view_context.link_to(t('dictionary.sign_in'), welcome_path)
  end
end
