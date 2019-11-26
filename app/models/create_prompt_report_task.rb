# Perform a request and log an error
class CreatePromptReportTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreatePromptReportLog.create_by(request: request)

    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} Perform request", level: :info) do
      request.error_check!
      twitter_user = create_twitter_user!(request.user)
      request.perform!(twitter_user)
    end
    request.finished!

    @log.update(status: true)

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end

  # 1. New record is created
  #   Return the record
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
          CreateTwitterUserRequest::RecentlyUpdated,
          CreateTwitterUserRequest::TooManyFriends => e
      ensure
        # Regardless of whether or not the TwitterUser record is created, the Unfriendship and the Unfollowership are updated.
        # Since the internal logic has been changed, otherwise the unfriends and the unfollowers will remain inaccurate.
        persisted_user = TwitterUser.latest_by(uid: user.uid)
        update_unfriendships(persisted_user) if persisted_user
      end
    end

    twitter_user
  end

  def update_unfriendships(twitter_user)
    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask  #{request.id} Import unfriendship", level: :info) do
      Unfriendship.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
        CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), compressed: true)
      end
    end

    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} Import unfollowership", level: :info) do
      Unfollowership.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
        CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), compressed: true)
      end
    end
  end
end
