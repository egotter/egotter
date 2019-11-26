# Perform a request and log an error
class CreateTwitterUserTask
  attr_reader :request, :twitter_user, :log

  def initialize(request)
    @request = request
  end

  # Create a record or raise an exception
  def start!
    @log = CreateTwitterUserLog.create_by(request: request)

    # Regardless of whether or not the TwitterUser record is created, the TwitterDB::User record is updated.
    CreateTwitterDBUserWorker.perform_async([request.uid], force_update: true)

    @twitter_user = request.perform!
    request.finished!
    @log.update(status: true)

    ([@twitter_user.uid] + @twitter_user.friend_uids + @twitter_user.follower_uids).each_slice(100) do |uids|
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), compressed: true)
    end

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end
end
