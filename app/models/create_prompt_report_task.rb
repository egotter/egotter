# Perform a request and log an error
class CreatePromptReportTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreatePromptReportLog.create_by(request: request)

    ApplicationRecord.benchmark("#{self.class} #{request.id} Perform request", level: :info) do
      request.error_check!

      if TwitterUser.exists?(uid: request.user.uid)
        ApplicationRecord.benchmark("#{self.class} #{request.id} Create twitter_user", level: :info) do
          create_twitter_user(request.user)
        end
      end

      request.perform!
    end
    request.finished!

    @log.update(status: true)

    self
  rescue => e
    @log.update(error_class: e.class, error_message: e.message)
    raise
  end

  private

  def create_twitter_user(user)
    create_request = CreateTwitterUserRequest.create(
        requested_by: 'report',
        user_id: user.id,
        uid: user.uid)

    twitter_user = nil
    begin
      ApplicationRecord.benchmark("#{self.class} #{request.id} create task start", level: :info) do
        twitter_user = CreateTwitterUserTask.new(create_request).start!.twitter_user
      end
    ensure
      # Regardless of whether or not the TwitterUser record is created, the Unfriendship and the Unfollowership are updated.
      # Since the internal logic has been changed, otherwise the unfriends and the unfollowers will remain inaccurate.

      twitter_user = TwitterUser.latest_by(uid: user.uid) unless twitter_user

      ApplicationRecord.benchmark("#{self.class} #{request.id} Unfriendship.import_by!", level: :info) do
        Unfriendship.import_by!(twitter_user: twitter_user)
      end

      ApplicationRecord.benchmark("#{self.class} #{request.id} Unfollowership.import_by!", level: :info) do
        Unfollowership.import_by!(twitter_user: twitter_user)
      end
    end

    # TODO Create TwitterDB::User of imported uids
  rescue CreateTwitterUserRequest::NotChanged, CreateTwitterUserRequest::RecentlyUpdated, CreateTwitterUserRequest::TooManyFriends => e
  end
end
