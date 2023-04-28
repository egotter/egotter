class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include SearchHistoriesConcern
  include SanitizationConcern
  include JobQueueingConcern

  skip_before_action :validate_api_authorization!
  skip_before_action :validate_account_suspension!
  skip_before_action :validate_dm_permission!
  skip_before_action :current_user_not_blocker?

  before_action :create_or_update_user, only: [:twitter, :twitter2]
  after_action :delete_tracking_params


  def twitter
    callback_from(:twitter)
  end

  def twitter2
    callback_from(:twitter2)
  end

  def failure
    # invalid_credentials csrf_detected session_expired service_unavailable timeout
    error_name = request.env['omniauth.error.type'].to_s
    redirect_to error_pages_omniauth_failure_path(via: current_via(error_name))
  end

  private

  def callback_from(provider)
    sign_in @user, event: :authentication
    ahoy.authenticate(@user)
    context = detect_context(@user)

    if context == :create
      # CreateWelcomeMessageWorker.perform_async(user.id)
      ImportBlockingRelationshipsWorker.perform_async(@user.id)
      ImportMutingRelationshipsWorker.perform_async(@user.id)
      track_invitation_event
    else
      UpdatePermissionLevelWorker.perform_async(@user.id)
    end

    track_registration_event(context)
    update_search_histories_when_signing_in(@user)
    update_twitter_db_user(@user.uid)
    request_creating_twitter_user(@user.uid)
    follow_egotter(@user)

    redirect_to after_callback_path(@user, context)
  end

  def create_or_update_user
    @user = User.update_or_create_with_token!(user_params)
  rescue => e
    Airbag.exception e, user_params: user_params
    redirect_to error_pages_omniauth_failure_path(via: current_via('save_error'))
  end

  def detect_context(user)
    user.created_at == user.updated_at ? :create : :update
  end

  def follow_egotter(user)
    if 'true' == session[:sign_in_follow]
      request = FollowRequest.create(user_id: user.id, uid: User::EGOTTER_UID, requested_by: 'sign_in')
      CreateFollowWorker.perform_async(request.id, enqueue_location: controller_name)
      CreateEgotterFollowerWorker.perform_async(user.id)
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

  def track_registration_event(context)
    name = context == :create ? 'Sign up' : 'Sign in'
    props = {via: session[:sign_in_via], click_id: session[:sign_in_click_id]}.compact.presence
    ahoy.track(name, props)
  end

  def track_invitation_event
    if (click_id = session[:sign_in_click_id]).present?
      props = {click_id: click_id, inviter_uid: click_id.split('-')[1]}.compact.presence
      ahoy.track('Invitation', props)
    end
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
        secret: values.credentials.secret || 'blank-secret',
        token: values.credentials.token,
        email: values.info.email,
    }.compact
  end
end

