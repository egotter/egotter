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
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
      return redirect_to root_path, alert: t('before_sign_in.login_failed_html', sign_in_path: welcome_path(via: "#{controller_name}/#{action_name}/sign_in_failed"))
    end

    ::Util::SearchedUids.new(Redis.client).delete(user.uid)
    ::Cache::PageCache.new.delete(user.uid)
    user.update(authorized: true)

    sign_in_and_redirect user, event: :authentication
    notification_status = t("dictionary.#{user.notification_setting.dm? ? 'enabled' : 'disabled'}")
    flash[:notice] = t('devise.omniauth_callbacks.success_html', kind: 'Twitter', status: notification_status, menu_path: menu_path) if is_navigational_format?
  end

  def failure
    %i(sign_in_from sign_out_from sign_in_via sign_in_referer sign_in_ab_test sign_in_follow redirect_path).each { |key| session.delete(key) }
    set_flash_message :alert, :failure, kind: 'Twitter', reason: request.env['omniauth.error.type'].to_s.humanize
    redirect_to after_omniauth_failure_path_for(resource_name)
  end

  private

  def user_params
    Hashie::Mash.new(request.env['omniauth.auth'].slice(:provider, :uid, :info, :credentials).to_h)
  end
end

