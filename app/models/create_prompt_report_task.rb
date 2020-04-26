# Perform a request and log an error
class CreatePromptReportTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreatePromptReportLog.create_by(request: request)

    bm_task_start('request.error_check!') { request.error_check! }

    twitter_user = nil

    begin
      bm_task_start('create_twitter_user!') { twitter_user = create_twitter_user!(request.user) }
    ensure
      # Regardless of whether or not the TwitterUser record is created, the Unfriendship and the Unfollowership are updated.
      # Since the internal logic has been changed, otherwise the unfriends and the unfollowers will remain inaccurate.
      if (persisted = TwitterUser.latest_by(uid: request.user.uid))
        unfriend_uids = unfollower_uids = nil
        bm_task_start('calculate_unfriendships') { unfriend_uids = persisted.calc_unfriend_uids }
        bm_task_start('update_unfriendships') { update_unfriendships(persisted.uid, unfriend_uids) }
        bm_task_start('calculate_unfollowerships') { unfollower_uids = persisted.calc_unfollower_uids }
        bm_task_start('update_unfollowerships') { update_unfollowerships(persisted.uid, unfollower_uids) }
      end
    end

    bm_task_start('request.perform!') { request.perform!(twitter_user) }

    request.finished!
    @log.update(status: true)

    if %i(you_are_removed not_changed).include?(request.kind)
      bm_task_start('update_api_caches') { update_api_caches(TwitterUser.latest_by(uid: request.user.uid)) }
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

    CreateTwitterUserTask.new(create_request).start!(:prompt_reports).twitter_user

  rescue CreateTwitterUserRequest::NotChanged,
      CreateTwitterUserRequest::TooShortCreateInterval,
      CreateTwitterUserRequest::TooManyFriends => e
    nil
  end

  def update_unfriendships(uid, unfriend_uids)
    Unfriendship.import_from!(uid, unfriend_uids)

    unfriend_uids.each_slice(100) do |uids|
      options = {user_id: request.user.id, compressed: true, enqueued_by: 'CreatePromptReportTask Unfriendship.import_from!'}
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), options)
    end
  end

  # This method was separated from the #update_unfriendships for benchmarking.
  def update_unfollowerships(uid, unfollower_uids)
    Unfollowership.import_from!(uid, unfollower_uids)

    unfollower_uids.each_slice(100) do |uids|
      options = {user_id: request.user.id, compressed: true, force_update: true, enqueued_by: ' CreatePromptReportTask Unfollowership.import_from!'}
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

  module Instrumentation
    def bm_task_start(message, &block)
      start = Time.zone.now
      yield
      @bm_task_start[message] = Time.zone.now - start
    end

    def start!(*args, &blk)
      @bm_task_start = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @bm_task_start['sum'] = @bm_task_start.values.sum
      @bm_task_start['elapsed'] = elapsed

      Rails.logger.info "Benchmark CreatePromptReportTask request_id=#{request.id} #{sprintf("%.3f sec", elapsed)}"
      Rails.logger.info "Benchmark CreatePromptReportTask request_id=#{request.id} #{@bm_task_start.inspect}"

      if elapsed > 30
        notice = Airbrake.build_notice('CreatePromptReportTask took more than 30 seconds')
        notice[:context][:component] = 'CreatePromptReportTask'
        notice[:params][:time] = elapsed
        notice[:params][:user] = {id: request.user.id}
        notice[:params][:request] = request.attributes
        notice[:params][:size] = TwitterUser.where(uid: request.user.uid).size
        notice[:params][:twitter_user] = TwitterUser.latest_by(uid: request.user.uid)&.attributes
        Airbrake.notify(notice)

        Rails.logger.info "Benchmark CreatePromptReportTask #{request.id} It took #{elapsed} seconds. size=#{notice[:params][:size]} #{notice[:params][:twitter_user]}"
      end
    end
  end
  prepend Instrumentation
end
