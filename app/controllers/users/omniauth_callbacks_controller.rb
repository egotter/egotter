class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include SearchHistoriesConcern
  include SanitizationConcern
  include JobQueueingConcern

  skip_before_action :current_user_authorized?
  skip_before_action :current_user_has_dm_permission?
  skip_before_action :current_user_not_blocker?

  after_action only: :twitter do
    update_search_histories_when_signing_in(@user)
    update_twitter_db_user
    enqueue_create_twitter_user_job_if_needed(@user.uid, user_id: @user.id)
  end

  after_action :follow_egotter, only: :twitter
  after_action :delete_tracking_params

  def twitter
    user, save_context = create_or_update_user
    return if performed?

    sign_in user, event: :authentication
    ahoy.authenticate(user)

    click_id = session[:sign_in_click_id]
    track_registration_event(
        save_context,
        via: session[:sign_in_via],
        click_id: click_id
    )
    if save_context == :create && click_id.present?
      track_invitation_event(click_id)
    end

    @user = user

    redirect_to after_callback_path(user, save_context)
  end

  def failure
    # invalid_credentials session_expired service_unavailable timeout
    error_name = request.env['omniauth.error.type'].to_s
    redirect_to error_pages_omniauth_failure_path(via: current_via(error_name))
  end

  private

  def create_or_update_user
    context = nil

    user = User.update_or_create_with_token!(user_params) do |user, ctx|
      if ctx == :create
        # CreateWelcomeMessageWorker.perform_async(user.id)
        ImportBlockingRelationshipsWorker.perform_async(user.id)
        ImportMutingRelationshipsWorker.perform_async(user.id)
      end
      UpdatePermissionLevelWorker.perform_async(user.id)
      context = ctx
    end

    [user, context]
  rescue => e
    logger.warn "##{__method__}: #{e.inspect} #{params.inspect}"
    redirect_to error_pages_omniauth_failure_path(via: current_via('save_error'))
    [nil, nil]
  end

  def follow_egotter
    if 'true' == session[:sign_in_follow]
      request = FollowRequest.create(user_id: @user.id, uid: User::EGOTTER_UID, requested_by: 'sign_in')
      CreateFollowWorker.perform_async(request.id, enqueue_location: controller_name)
      CreateEgotterFollowerWorker.perform_async(@user.id)
    end
  end

  def delete_tracking_params
    %i(
      sign_in_from
      sign_out_from
      sign_in_via
      sign_in_click_id
      sign_in_referer
      sign_in_ab_test
      sign_in_follow
      redirect_path
      force_login
    ).each { |key| session.delete(key) }
  end

  def track_registration_event(context, via:, click_id: nil)
    name = context == :create ? 'Sign up' : 'Sign in'
    ahoy.track(name, {via: via, click_id: click_id}.compact.presence)
  end

  def track_invitation_event(click_id)
    ahoy.track('Invitation', {click_id: click_id, inviter_uid: click_id.split('-')[1]}.compact.presence)
  end

  def after_callback_path(user, save_context)
    options = {redirect_path: after_callback_redirect_path(user, save_context)}
    if save_context == :create
      after_sign_up_path(options)
    else
      after_sign_in_path(options)
    end
  end

  def after_callback_redirect_path(user, save_context)
    url = session.delete(:redirect_path)
    url = start_path(save_context: save_context, via: "after_sign_in_#{save_context}") if url.blank?
    url = sanitized_redirect_path(url)
    url = url.sub!(':screen_name', user.screen_name) if url.include?(':screen_name')

    append_query_params(url, follow_dialog: 1, share_dialog: 1)
  end

  ANCHOR_REGEXP = /(#[a-zA-Z0-9_-]+)/

  def append_query_params(path, params)
    path += path.include?('?') ? '&' : '?'
    path + params.to_query

    if path.match?(ANCHOR_REGEXP)
      anchor = path.match(ANCHOR_REGEXP)[0]
      path.remove!(ANCHOR_REGEXP)
      path = path + anchor
    end

    path
  end

  def user_params
    values = Hashie::Mash.new(request.env['omniauth.auth'].symbolize_keys.slice(:provider, :uid, :info, :credentials).to_h)

    {
        uid: values.uid,
        screen_name: values.info.nickname,
        secret: values.credentials.secret,
        token: values.credentials.token,
        email: values.info.email,
    }.compact
  end
end

