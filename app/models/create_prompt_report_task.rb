# Perform a request and log an error
class CreatePromptReportTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreatePromptReportLog.create_by(request: request)

    start = Time.zone.now

    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} Perform request", level: :info) do
      request.error_check!
      twitter_user = create_twitter_user!(request.user)
      request.perform!(twitter_user)
    end

    elapsed = Time.zone.now - start
    if elapsed > 3000
      records_size = TwitterUser.where(uid: request.user.uid).size
      logger.info { "Benchmark CreatePromptReportTask too slow #{request.id} #{records_size}" }
    end

    request.finished!
    @log.update(status: true)

    if %i(you_are_removed not_changed).include?(request.kind)
      update_api_caches(TwitterUser.latest_by(uid: request.user.uid))
    end

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end

  # 1. New record is created
  #   Return the record
  #
  # 2. New record is NOT created
  #     2.1. Because the user is not changed
  #       Return nil
  #     2.2. Because something happened
  #       Raise an error
  #
  def create_twitter_user!(user)
    create_request = CreateTwitterUserRequest.create(
        requested_by: 'report',
        user_id: user.id,
        uid: user.uid)

    twitter_user = nil

    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} Create twitter_user", level: :info) do
      begin
        twitter_user = CreateTwitterUserTask.new(create_request).start!.twitter_user
      rescue CreateTwitterUserRequest::NotChanged,
          CreateTwitterUserRequest::TooShortCreateInterval,
          CreateTwitterUserRequest::TooManyFriends => e
      ensure
        # Regardless of whether or not the TwitterUser record is created, the Unfriendship and the Unfollowership are updated.
        # Since the internal logic has been changed, otherwise the unfriends and the unfollowers will remain inaccurate.
        update_unfriendships(TwitterUser.latest_by(uid: user.uid))
      end
    end

    twitter_user
  end

  def update_unfriendships(twitter_user)
    return unless twitter_user

    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} Import unfriendship", level: :info) do
      Unfriendship.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
        CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), user_id: request.user.id, compressed: true, enqueued_by: 'CreatePromptReportTask Unfriendship.import_by!')
      end
    end

    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} Import unfollowership", level: :info) do
      Unfollowership.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
        CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), user_id: request.user.id, compressed: true, force_update: true, enqueued_by: ' CreatePromptReportTaskUnfollowership.import_by!')
      end
    end
  end

  def update_api_caches(twitter_user)
    return unless twitter_user

    twitter_user.unfollowers.take(PromptReport::UNFOLLOWERS_SIZE_LIMIT).each do |unfollower|
      FetchUserForCachingWorker.perform_async(unfollower.uid, user_id: request.user.id, enqueued_at: Time.zone.now)
      FetchUserForCachingWorker.perform_async(unfollower.screen_name, user_id: request.user.id, enqueued_at: Time.zone.now)
      # TwitterDB::User has already been forcibly updated in #update_unfriendships .
    end
  end
end
