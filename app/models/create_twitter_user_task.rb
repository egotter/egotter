# Perform a request and log an error
class CreateTwitterUserTask
  attr_reader :request, :twitter_user, :log

  def initialize(request)
    @request = request
  end

  # Create a record or raise an exception
  # context:
  #   :prompt_reports
  #   :periodic_reports
  def start!(context = nil)
    @log = CreateTwitterUserLog.create_by(request: request)

    update_target_user(request)

    @twitter_user = request.perform!(context)
    request.finished!
    @log.update(status: true)

    update_friends_and_followers(@twitter_user)

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end

  private

  def update_target_user(request)
    # Regardless of whether or not the TwitterUser record is created, the TwitterDB::User record is updated.
    CreateTwitterDBUserWorker.perform_async([request.uid], user_id: request.user_id, force_update: true, enqueued_by: "#{self.class}##{__method__}")
  end

  def update_friends_and_followers(twitter_user)
    uids = ([twitter_user.uid] + twitter_user.friend_uids + twitter_user.follower_uids).uniq
    options = {user_id: request.user_id, compressed: true, enqueued_by: "#{self.class}##{__method__}"}

    uids.each_slice(100) do |uids_array|
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids_array), options)
    end
  end
end
