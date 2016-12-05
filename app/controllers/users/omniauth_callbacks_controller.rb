class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Concerns::Logging

  def twitter
    begin
      user = User.update_or_create_for_oauth_by!(user_params) do |user, context|
        via = session[:sign_in_via] ? session.delete(:sign_in_via) : ''
        follow = 'true' == session.delete(:sign_in_follow)
        create_sign_in_log(user, context: context, via: via, follow: follow)
        FollowEgotterWorker.perform_async(user.id) if follow
      end
    rescue =>  e
      return redirect_to root_path, alert: t('before_sign_in.login_failed', sign_in_link: view_context.link_to(t('dictionary.sign_in'), welcome_path))
    end

    delete_uid(user)

    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
  end

  private

  def delete_uid(user)
    redis = Redis.client
    Util::SearchedUidList.new(redis).delete(user.uid)
    user.update(authorized: true)
    Util::TooManyFriendsUidList.new(redis).delete(user.uid)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user.inspect}"
  end

  def user_params
    Hashie::Mash.new(request.env['omniauth.auth'].slice(:provider, :uid, :info, :credentials).to_h)
  end
end

