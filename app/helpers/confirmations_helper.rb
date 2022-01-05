module ConfirmationsHelper
  def confirmation_path
    redirect_path = send("#{controller_name}_path", share_dialog: 1, follow_dialog: 1, sign_in_dialog: 1, purchase_dialog: 1, user_token: params[:user_token], via: current_via)
    sign_in_path(force_login: !user_signed_in?, follow: follow_confirmations_page?, via: current_via, redirect_path: redirect_path)
  end

  def sign_in_as_confirmation_user?
    user_signed_in? && params[:user_token] && current_user.valid_user_token?(params[:user_token])
  end

  def follow_confirmations_page?
    controller_name == 'follow_confirmations'
  end
end
