class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken do
    redirect_to '/', alert: t('before_sign_in.session_expired', sign_in_link: sign_in_link)
  end

  helper_method :admin_signed_in?, :sign_in_link, :sign_out_link, :search_oneself?, :search_others?

  private
  def admin_signed_in?
    user_signed_in? && current_user.admin?
  end

  def sign_in_link
    view_context.link_to(t('dictionary.sign_in'), welcome_path)
  end

  def sign_out_link
    view_context.link_to(t('dictionary.sign_out'), destroy_user_session_path)
  end

  def search_oneself?(uid)
    user_signed_in? && current_user.uid.to_i == uid.to_i
  end

  def search_others?(uid)
    user_signed_in? && current_user.uid.to_i != uid.to_i
  end
end
