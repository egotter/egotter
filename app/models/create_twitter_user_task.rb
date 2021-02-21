# Perform a request and log an error
class CreateTwitterUserTask
  attr_reader :request, :twitter_user

  def initialize(request)
    @request = request
  end

  # Create a record or raise an exception
  # context:
  #   :reporting
  def start!(context = nil)
    @twitter_user = @request.perform!(context)
    @request.finished!

    update_friends_and_followers(@twitter_user, @request)

    self
  rescue => e
    @request.update(status_message: e.class) if @request
    raise
  end

  private

  def update_friends_and_followers(twitter_user, request)
    if (older_record = TwitterUser.where('created_at < ?', twitter_user.created_at).latest_by(uid: twitter_user.uid))
      new_friend_uids = twitter_user.friend_uids - older_record.friend_uids
      new_follower_uids = twitter_user.follower_uids - older_record.follower_uids
      uids = ([twitter_user.uid] + new_friend_uids + new_follower_uids).uniq
    else
      uids = ([twitter_user.uid] + twitter_user.friend_uids + twitter_user.follower_uids).uniq
    end
    CreateHighPriorityTwitterDBUserWorker.compress_and_perform_async(uids, user_id: request.user_id, request_id: request.id, enqueued_by: "#{self.class}##{__method__}")
  end
end
