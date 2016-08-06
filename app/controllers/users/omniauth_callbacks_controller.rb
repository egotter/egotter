class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Logging

  def twitter
    begin
      user = User.update_or_create_for_oauth_by!(user_params) do |user, context|
        create_sign_in_log(user.id, context)
      end
    rescue =>  e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
      return redirect_to '/', alert: t('before_sign_in.login_failed', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
    end

    FollowEgotterWorker.perform_async(user.id)
    delete_uid(user)

    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
  end

  private

  def delete_uid(user)
    redis = Redis.client
    Util::SearchedUidList.new(redis).delete(user.uid, user.id)
    Util::UnauthorizedUidList.new(redis).delete(user.uid, user.id)
    Util::TooManyFriendsUidList.new(redis).delete(user.uid, user.id)
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user.inspect}"
  end

  def user_params
    Hashie::Mash.new(request.env['omniauth.auth'].slice(:provider, :uid, :info, :credentials).to_h)
  end
end

