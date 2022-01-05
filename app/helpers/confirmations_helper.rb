module ConfirmationsHelper
  def sign_in_as_confirmation_user?
    user_signed_in? && params[:user_token] && current_user.valid_user_token?(params[:user_token])
  end
end
