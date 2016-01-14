class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def twitter
    @user = User.find_or_create_for_oauth_by!(user_params)

    sign_in_and_redirect @user, :event => :authentication
    set_flash_message(:notice, :success, :kind => 'Twitter') if is_navigational_format?
  end

  private
  def user_params
    Hashie::Mash.new(request.env["omniauth.auth"].slice(:provider, :uid, :info, :credentials).to_h)
  end
end

