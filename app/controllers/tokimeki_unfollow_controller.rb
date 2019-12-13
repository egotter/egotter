class TokimekiUnfollowController < ApplicationController
  include Concerns::SearchRequestConcern
  include Concerns::UnfriendsConcern

  before_action :require_login!, only: %i(cleanup unfollow keep)

  rescue_from Exception do |ex|
    if AccountStatus.unauthorized?(ex)
      redirect_to tokimeki_unfollow_top_path(via: build_via('unauthorized')), alert: signed_in_user_not_authorized_message
    else
      logger.warn "#{controller_name}##{action_name} #{current_user_id} #{ex.inspect}"
      redirect_to tokimeki_unfollow_top_path(via: build_via('something_error')), alert: unknown_alert_message(ex)
    end
  end

  before_action only: :cleanup do
    if current_twitter_user[:friends_count] >= 10000
      redirect_to root_path(via: build_via), alert: t('after_sign_in.tokimeki_unfollow_too_many_friends')
    else
      initialize_data!
      if current_tokimeki_user.processed_count >= current_tokimeki_user.friendships.size
        redirect_to root_path(via: build_via), notice: t('tokimeki_unfollow.cleanup.finish')
      end
    end
  end

  before_action do
    push_referer
    create_search_log
  end

  def new
  end

  def cleanup
    @user = current_tokimeki_user
    @friend = Friend.new(current_friend(@user))
    @statuses = current_tweets(@friend.uid)

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
    if AccountStatus.not_found?(e) || AccountStatus.suspended?(e) || AccountStatus.blocked?(e)
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

    CreateTwitterDBUserWorker.perform_async(friend_uids, user_id: current_user.id, enqueued_by: 'tokimeki unfollow')

    ActiveRecord::Base.transaction do
      Tokimeki::User.create!(uid: user[:id], screen_name: user[:screen_name], friends_count: user[:friends_count], processed_count: 0)
      Tokimeki::Friendship.import_from!(current_user.uid, friend_uids)
    end
  end
end
