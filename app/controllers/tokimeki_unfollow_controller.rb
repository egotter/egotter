class TokimekiUnfollowController < ApplicationController
  include SearchRequestCreation

  before_action :require_login!, only: %i(cleanup unfollow keep)

  rescue_from StandardError do |ex|
    if TwitterApiStatus.unauthorized?(ex)
      redirect_to error_pages_twitter_error_unauthorized_path(via: current_via('unauthorized'))
    else
      Airbag.warn "#{controller_name}##{action_name} #{current_user_id} #{ex.inspect}"
      redirect_to tokimeki_unfollow_top_path(via: current_via('something_error')), alert: unknown_alert_message(ex)
    end
  end

  before_action only: :cleanup do
    if current_twitter_user[:friends_count] >= 10000
      redirect_to root_path(via: current_via), alert: t('after_sign_in.tokimeki_unfollow_too_many_friends')
    else
      initialize_data!
      if current_tokimeki_user.processed_count >= current_tokimeki_user.friendships.size
        redirect_to root_path(via: current_via), notice: t('tokimeki_unfollow.cleanup.finish')
      end
    end
  end

  def new
  end

  def cleanup
    @user = current_tokimeki_user
    begin
      @friend = Friend.new(current_friend(@user))
      @statuses = current_tweets(@friend.uid)
    rescue => e
      if TwitterApiStatus.not_found?(e) || TwitterApiStatus.suspended?(e) || TwitterApiStatus.blocked?(e) || TwitterApiStatus.protected?(e)
        @user.increment(:processed_count).save!
        retry
      else
        raise
      end
    end

    @twitter_user = TwitterUser.latest_by(uid: @friend.uid)
    @twitter_user = TwitterUser.build_by(user: @friend.user) unless @twitter_user
  end

  def unfollow
    ActiveRecord::Base.transaction do
      current_tokimeki_user.increment(:processed_count).save!
      Tokimeki::Unfriendship.create!(
          user_uid: current_user.uid,
          friend_uid: params[:uid],
          sequence: Tokimeki::Unfriendship.where(user_uid: current_user.uid).size
      )
    end
    head :ok
  end

  def keep
    current_tokimeki_user.increment(:processed_count).save!
    head :ok
  end

  private

  class Friend
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def uid
      @user[:id]
    end

    def screen_name
      @user[:screen_name]
    end
  end

  def current_tokimeki_user
    @current_tokimeki_user ||= Tokimeki::User.find_by(uid: current_user.uid)
  end

  def current_friend(user)
    friend_uids ||= user.friendships.pluck(:friend_uid)

    uid = friend_uids[user.processed_count]
    request_context_client.user(uid)

  rescue => e
    if TwitterApiStatus.not_found?(e) || TwitterApiStatus.suspended?(e) || TwitterApiStatus.blocked?(e) || TwitterApiStatus.protected?(e)
      user.increment(:processed_count).save!
      retry
    else
      raise
    end
  end

  def current_tweets(uid)
    request_context_client.user_timeline(uid, count: 100).reject do |tweet|
      tweet[:text].to_s.starts_with?('@')
    end.take(20).map { |t| Hashie::Mash.new(t) }
  end

  def current_twitter_user
    request_context_client.user(current_user.uid)
  end

  # TODO Reset function
  def initialize_data!
    return if current_tokimeki_user

    user = current_twitter_user
    friend_uids = request_context_client.friend_ids(user[:id])

    friend_uids.each_slice(100) do |uids|
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), user_id: current_user.id, compressed: true, enqueued_by: 'tokimeki unfollow')
    end

    ActiveRecord::Base.transaction do
      Tokimeki::User.create!(uid: user[:id], screen_name: user[:screen_name], friends_count: user[:friends_count], processed_count: 0)
      Tokimeki::Friendship.import_from!(current_user.uid, friend_uids)
    end
  end
end
