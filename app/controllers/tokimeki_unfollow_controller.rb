class TokimekiUnfollowController < UnfriendsAndUnfollowers

  before_action only: :cleanup do
    redirect_to tokimeki_unfollow_top_path unless user_signed_in?
  end

  before_action only: :cleanup do
    if !Tokimeki::User.exists?(uid: current_user.uid) && !save_data
      redirect_to root_path, alert: t('after_sign_in.tokimeki_unfollow_too_many_friends')
    end
  end

  before_action :require_login!, only: %i(unfollow keep)

  before_action do
    push_referer
    create_search_log
  end

  def new
  end

  def cleanup
    @user = Tokimeki::User.find_by(uid: current_user.uid)

    friend_uids = @user.friendships.pluck(:friend_uid)
    if @user.processed_count >= friend_uids.size
      return redirect_to root_path, notice: t('.finish')
    end

    friend_id = @friend = nil
    begin
      friend_id = friend_uids[@user.processed_count]
      @friend = Hashie::Mash.new(request_context_client.user(friend_id))
    rescue Twitter::Error::NotFound => e
      if e.message == 'User not found.'
        @user.increment(:processed_count).save!
        retry
      else
        raise
      end
    end

    @statuses = request_context_client.user_timeline(friend_id, count: 100).select {|s| !s[:text].to_s.starts_with?('@')}.take(20).map {|s| Hashie::Mash.new(s)}

    @twitter_user = TwitterUser.exists?(friend_id) ? TwitterUser.latest_by(uid: friend_id) : TwitterUser.build_by(user: @friend)
  end

  def unfollow
    ActiveRecord::Base.transaction do
      Tokimeki::User.find_by(uid: current_user.uid).increment(:processed_count).save!
      Tokimeki::Unfriendship.create!(user_uid: current_user.uid, friend_uid: params[:uid], sequence: Tokimeki::Unfriendship.where(user_uid: current_user.uid).size)
    end
    head :ok
  end

  def keep
    Tokimeki::User.find_by(uid: current_user.uid).increment(:processed_count).save!
    head :ok
  end

  private

  def save_data
    t_user = request_context_client.user(current_user.uid)
    return false if t_user[:friends_count].to_i >= 10000

    friend_ids = request_context_client.friend_ids(t_user[:id])
    CreateTwitterDBUserWorker.perform_async(friend_ids)

    ActiveRecord::Base.transaction do
      user = Tokimeki::User.find_or_create_by!(uid: t_user[:id], screen_name: t_user[:screen_name], friends_count: t_user[:friends_count], processed_count: 0)
      Tokimeki::Friendship.import_from!(user.uid, friend_ids)
    end

    true
  end
end
