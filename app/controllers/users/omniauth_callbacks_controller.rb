class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def twitter
    user = User.find_or_create_for_oauth_by!(user_params)
    FollowEgotterWorker.perform_async(user.id)
    delete_uid(user)

    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
  end

  private

  def delete_uid(user)
    redis = Redis.client
    SearchedUidList.new(redis).delete(user.uid)
    UnauthorizedUidList.new(redis).delete(user.uid)
    TooManyFriendsUidList.new(redis).delete(user.uid)
  rescue => e
    logger.warn "#{e}: #{e.message} #{user.inspect}"
  end

  def user_params
    Hashie::Mash.new(request.env["omniauth.auth"].slice(:provider, :uid, :info, :credentials).to_h)
  end
end

