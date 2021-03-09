module ModalsHelper
  def show_follow_modal?
    user_signed_in? && params[:follow_dialog] == '1' && !current_user.following_egotter?
  end

  def show_share_modal?
    user_signed_in? && params[:share_dialog] == '1'
  end

  def show_purchase_modal?
    user_signed_in? && params[:purchase_dialog] == '1' && current_user.following_egotter? && !current_user.has_valid_subscription?
  end

  def show_continuous_sign_in_modal?
    user_signed_in? && current_user.continuous_sign_in?
  end

  def show_sign_in_modal?
    !user_signed_in? && (params[:sign_in_dialog] == '1' || from_search_engine?)
  end
end
