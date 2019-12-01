class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Concerns::SearchHistoriesConcern
  include Concerns::SanitizationConcern
  include Concerns::JobQueueingConcern

  def twitter
    via = session[:sign_in_via] ? session.delete(:sign_in_via) : ''
    referer = session[:sign_in_referer] ? session.delete(:sign_in_referer) : ''
    ab_test = session[:sign_in_ab_test] ? session.delete(:sign_in_ab_test) : ''
    follow = 'true' == session.delete(:sign_in_follow)
    tweet = 'true' == session.delete(:sign_in_tweet)
    force_login = 'true' == session.delete(:force_login)

    begin
      user = User.update_or_create_with_token!(user_params) do |user, context|
        create_sign_in_log(user, context: context, via: via, follow: follow, tweet: tweet, referer: referer, ab_test: ab_test)
        CreateWelcomeMessageWorker.perform_async(user.id) if context == :create
        UpdatePermissionLevelWorker.perform_async(user.id, enqueued_at: Time.zone.now, send_test_report: force_login)
      end
    rescue =>  e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
      return redirect_to root_path, alert: t('before_sign_in.login_failed_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/sign_in_failed"))
    end

    update_search_histories_when_signing_in(user)
    FollowRequest.create(user_id: user.id, uid: User::EGOTTER_UID) if follow
    TweetEgotterWorker.perform_async(user.id, egotter_share_text(shorten_url: false, via: "share_tweet/#{user.screen_name}")) if tweet
    EnqueuedSearchRequest.new.delete(user.uid)
    DeleteNotFoundUserWorker.perform_async(user.screen_name)
    DeleteForbiddenUserWorker.perform_async(user.screen_name)
    CreateTwitterDBUserWorker.perform_async([user.uid], force_update: true)
    enqueue_create_twitter_user_job_if_needed(user.uid, user_id: current_user.id, requested_by: 'sign_in')

    flash[:notice] = after_sign_in_message(user)
    sign_in user, event: :authentication
    redirect_to after_sign_in_path_for(user)
  end

  def failure
    %i(
      sign_in_from
      sign_out_from
      sign_in_via
      sign_in_referer
      sign_in_ab_test
      sign_in_follow
      sign_in_tweet
      sign_in_tweet_text
      redirect_path
      force_login
    ).each { |key| session.delete(key) }

    if user_signed_in?
      redirect_to root_path
    else
      flash[:notice] = after_failure_message(request.env['omniauth.error.type'].to_s)
      redirect_to after_omniauth_failure_path_for(resource_name)
    end
  end

  private

  def after_sign_in_path_for(user)
    redirect_path = sanitized_redirect_path(session.delete(:redirect_path) || root_path)
    append_query_params(redirect_path, follow_dialog: 1, share_dialog: 1)
  end

  def after_sign_in_message(user)
    t('devise.omniauth_callbacks.success_with_notification_status_html', kind: 'Twitter', status: notification_status_message(user), url: settings_path(via: 'after_sign_in'))
  end

  def after_failure_message(reason)
    unless %w(invalid_credentials session_expired service_unavailable).include?(reason)
      logger.warn "#{self.class}##{__method__}: unknown reason #{reason}"
    end

    if %w(invalid_credentials session_expired).include?(reason)
      url = sign_in_path(via: "#{controller_name}/#{action_name}/retry_invalid_or_expired")
      t('devise.omniauth_callbacks.failure_with_retry_message_html', kind: 'Twitter', url: url)
    elsif %w(service_unavailable).include?(reason)
      url = sign_in_path(via: "#{controller_name}/#{action_name}/retry_service_unavailable")
      t('devise.omniauth_callbacks.service_unavailable_html', kind: 'Twitter', url: url)
    else
      url = sign_in_path(via: "#{controller_name}/#{action_name}/retry_something_error")
      t('devise.omniauth_callbacks.failure_with_retry_message_html', kind: 'Twitter', url: url)
    end
  end

  def notification_status_message(user)
    if user.notification_setting.dm?
      t('devise.omniauth_callbacks.enabled')
    else
      t('devise.omniauth_callbacks.disabled')
    end
  end

  def user_params
    values = Hashie::Mash.new(request.env['omniauth.auth'].symbolize_keys.slice(:provider, :uid, :info, :credentials).to_h)

    {
        uid: values.uid,
        screen_name: values.info.nickname,
        secret: values.credentials.secret,
        token: values.credentials.token,
        authorized: true,
        email: values.info.email,
    }.compact
  end
end

