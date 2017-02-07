class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Concerns::Logging

  def twitter
    begin
      user = User.update_or_create_for_oauth_by!(user_params) do |user, context|
        via = session[:sign_in_via] ? session.delete(:sign_in_via) : ''
        referer = session[:sign_in_referer] ? session.delete(:sign_in_referer) : ''
        ab_test = session[:sign_in_ab_test] ? session.delete(:sign_in_ab_test) : ''
        follow = 'true' == session.delete(:sign_in_follow)
        create_sign_in_log(user, context: context, via: via, follow: follow, referer: referer, ab_test: ab_test)
        FollowEgotterWorker.perform_async(user.id) if follow
      end
    rescue =>  e
      sign_in_link = view_context.link_to(t('dictionary.sign_in'), welcome_path(via: "#{controller_name}/#{action_name}/sign_in_failed"))
      return redirect_to root_path, alert: t('before_sign_in.login_failed', sign_in_link: sign_in_link)
    end

    delete_uid(user)

    sign_in_and_redirect user, event: :authentication
    set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
  end

  def failure
    %i(sign_in_from sign_out_from sign_in_via sign_in_referer sign_in_ab_test sign_in_follow redirect_path).each { |key| session.delete(key) }
    set_flash_message :alert, :failure, kind: 'Twitter', reason: request.env['omniauth.error.type'].to_s.humanize
    redirect_to after_omniauth_failure_path_for(resource_name)
  end

  private

  def delete_uid(user)
    redis = Redis.client
    Util::SearchedUids.new(redis).delete(user.uid)
    user.update(authorized: true)
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{user.inspect}"
  end

  def user_params
    Hashie::Mash.new(request.env['omniauth.auth'].slice(:provider, :uid, :info, :credentials).to_h)
  end
end

