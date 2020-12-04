class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include SearchHistoriesConcern
  include SanitizationConcern
  include JobQueueingConcern

  after_action only: :twitter do
    if @follow
      request = FollowRequest.create(user_id: @user.id, uid: User::EGOTTER_UID, requested_by: 'sign_in')
      CreateFollowWorker.perform_async(request.id, enqueue_location: controller_name)
      CreateEgotterFollowerWorker.perform_async(@user.id)
    end

    update_search_histories_when_signing_in(@user)

    CreateTwitterDBUserWorker.perform_async([@user.uid], user_id: @user.id, force_update: true, enqueued_by: 'twitter callback after signing in')

    enqueue_create_twitter_user_job_if_needed(@user.uid, user_id: @user.id)
  end

  def twitter
    via = session[:sign_in_via] ? session.delete(:sign_in_via) : ''
    referer = session[:sign_in_referer] ? session.delete(:sign_in_referer) : ''
    follow = 'true' == session.delete(:sign_in_follow)
    force_login = 'true' == session.delete(:force_login)

    save_context = nil
    begin
      user = User.update_or_create_with_token!(user_params) do |user, context|
        if context == :create
          CreateWelcomeMessageWorker.perform_async(user.id)
          ImportBlockingRelationshipsWorker.perform_async(user.id)
        end
        UpdatePermissionLevelWorker.perform_async(user.id)
        save_context = context
      end
    rescue => e
      logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
      return redirect_to root_path(via: current_via('save_error')), alert: t('.login_failed_html', url: sign_in_path(via: "#{controller_name}/#{action_name}/sign_in_failed"))
    end

    sign_in user, event: :authentication
    track_sign_in_event(context: save_context, via: via)
    redirect_to after_callback_path(user, save_context: save_context, force_login: force_login)

    @user = user
    @follow = follow
  end

  def failure
    %i(
      sign_in_from
      sign_out_from
      sign_in_via
      sign_in_referer
      sign_in_ab_test
      sign_in_follow
      redirect_path
      force_login
    ).each { |key| session.delete(key) }

    message = after_failure_message(request.env['omniauth.error.type'].to_s)
    redirect_to root_path(via: current_via("signed_in_#{user_signed_in?}")), alert: message
  end

  private

  def after_callback_path(user, save_context:, force_login: false)
    options = {redirect_path: after_callback_redirect_path(user, save_context: save_context, force_login: force_login)}
    if save_context == :create
      after_sign_up_path(options)
    else
      after_sign_in_path(options)
    end
  end

  def after_callback_redirect_path(user, save_context:, force_login:)
    url = session.delete(:redirect_path)
    url = start_path(save_context: save_context, via: "after_sign_in_#{save_context}") if url.blank?
    url = sanitized_redirect_path(url)
    url = url.sub!(':screen_name', user.screen_name) if url.include?(':screen_name')

    append_query_params(url, follow_dialog: 1, share_dialog: 1)
  end

  KNOWN_REASONS = %w(invalid_credentials session_expired service_unavailable timeout)

  def after_failure_message(reason)
    if KNOWN_REASONS.include?(reason)
      logger.info "#{self.class}##{__method__}: Reason #{reason}"
    else
      logger.warn "#{self.class}##{__method__}: Unknown reason #{reason}"
    end

    if user_signed_in?
      t('devise.omniauth_callbacks.failure_with_already_signed_in_html')
    else
      if %w(invalid_credentials session_expired).include?(reason)
        url = sign_in_path(via: "#{controller_name}/#{action_name}/retry_invalid_or_expired")
        t('devise.omniauth_callbacks.failure_with_retry_message_html', kind: 'Twitter', url: url)
      elsif %w(service_unavailable timeout).include?(reason)
        url = sign_in_path(via: "#{controller_name}/#{action_name}/retry_service_unavailable")
        t('devise.omniauth_callbacks.service_unavailable_html', kind: 'Twitter', url: url)
      else
        url = sign_in_path(via: "#{controller_name}/#{action_name}/retry_something_error")
        t('devise.omniauth_callbacks.failure_with_retry_message_html', kind: 'Twitter', url: url)
      end
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

