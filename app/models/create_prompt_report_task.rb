# Perform a request and log an error
class CreatePromptReportTask
  attr_reader :request, :log

  module Instrumentation
    def start!(*args, &blk)
      start = Time.zone.now
      super

      if (time = Time.zone.now - start) > 30
        notice = Airbrake.build_notice('CreatePromptReportTask took more than 30 seconds')
        notice[:context][:component] = 'CreatePromptReportTask'
        notice[:params][:user] = {id: request.user.id}
        notice[:params][:request] = request.attributes
        notice[:params][:size] = TwitterUser.where(uid: request.user.uid).size
        notice[:params][:twitter_user] = TwitterUser.latest_by(uid: request.user.uid)&.attributes
        Airbrake.notify(notice)

        Rails.logger.info "Benchmark CreatePromptReportTask #{request.id} It took #{time} seconds. #{notice[:params][:size]} #{notice[:params][:twitter_user]}"
      end
    end
  end
  prepend Instrumentation

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreatePromptReportLog.create_by(request: request)

    twitter_user = nil

    benchmark('request.error_check!') { request.error_check! }
    begin
      benchmark('create_twitter_user!') { twitter_user = create_twitter_user!(request.user) }
    ensure
      # Regardless of whether or not the TwitterUser record is created, the Unfriendship and the Unfollowership are updated.
      # Since the internal logic has been changed, otherwise the unfriends and the unfollowers will remain inaccurate.
      persisted = TwitterUser.latest_by(uid: request.user.uid)
      benchmark('update_unfriendships') { update_unfriendships(persisted) }
      benchmark('update_unfollowerships') { update_unfollowerships(persisted) }
    end
    benchmark('request.perform!') { request.perform!(twitter_user) }

    request.finished!
    @log.update(status: true)

    if %i(you_are_removed not_changed).include?(request.kind)
      benchmark('update_api_caches') { update_api_caches(TwitterUser.latest_by(uid: request.user.uid)) }
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

    CreateTwitterUserTask.new(create_request).start!.twitter_user

  rescue CreateTwitterUserRequest::NotChanged,
      CreateTwitterUserRequest::TooShortCreateInterval,
      CreateTwitterUserRequest::TooManyFriends => e
    nil
  end

  def update_unfriendships(twitter_user)
    return unless twitter_user

    Unfriendship.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
      options = {user_id: request.user.id, compressed: true, enqueued_by: 'CreatePromptReportTask Unfriendship.import_by!'}
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), options)
    end
  end

  # This method was separated from the #update_unfriendships for benchmarking.
  def update_unfollowerships(twitter_user)
    return unless twitter_user

    Unfollowership.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
      options = {user_id: request.user.id, compressed: true, force_update: true, enqueued_by: ' CreatePromptReportTask Unfollowership.import_by!'}
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), options)
    end
  end

  def update_api_caches(twitter_user)
    return unless twitter_user

    # TODO Monitor cache hit ratio
    twitter_user.unfollowers.take(PromptReport::UNFOLLOWERS_SIZE_LIMIT).each do |unfollower|
      FetchUserForCachingWorker.perform_async(unfollower.uid, user_id: request.user.id, enqueued_at: Time.zone.now)
      FetchUserForCachingWorker.perform_async(unfollower.screen_name, user_id: request.user.id, enqueued_at: Time.zone.now)
      # TwitterDB::User has already been forcibly updated in #update_unfriendships .
    end
  end

  def benchmark(message, &block)
    ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{request.id} #{message}", level: :info, &block)
  end
end
