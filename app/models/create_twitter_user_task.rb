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

    new_uids = update_new_friends_and_new_followers(@twitter_user, @request.user_id)
    update_friends_and_followers(@twitter_user, @request.user_id, new_uids)

    self
  rescue => e
    @request.update(status_message: e.class) if @request
    raise
  end

  private

  def update_new_friends_and_new_followers(twitter_user, user_id)
    uids = ([twitter_user.uid] + twitter_user.calc_new_friend_uids + twitter_user.calc_new_follower_uids).uniq
    if uids.any?
      CreateHighPriorityTwitterDBUserWorker.compress_and_perform_async(uids, user_id: user_id, enqueued_by: "#{self.class}##{__method__}")
    end
    uids
  end

  def update_friends_and_followers(twitter_user, user_id, reject_uids)
    uids = (twitter_user.friend_uids + twitter_user.follower_uids - reject_uids).uniq
    if uids.any?
      CreateTwitterDBUserWorker.compress_and_perform_async(uids, user_id: user_id, enqueued_by: "#{self.class}##{__method__}")
    end
  end
end
