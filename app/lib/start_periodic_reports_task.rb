class StartPeriodicReportsTask
  def initialize(period: nil, user_ids: nil, threads: nil)
    @period = period || 'none'
    @threads = threads || 6

    if user_ids.present?
      @user_ids = self.class.reject_stop_requested_user_ids(user_ids)
    elsif period == 'morning'
      @user_ids = self.class.morning_user_ids
    elsif period == 'afternoon'
      @user_ids = self.class.afternoon_user_ids
    elsif period == 'night'
      @user_ids = self.class.night_user_ids
    end

    @slack = SlackBotClient.channel('cron')
    @last_response = {}
  end

  def start
    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: StartPeriodicReportsTask is stopped', period: @period
      return
    end

    @start_time = Time.zone.now
    @last_response = @slack.post_message("Start sending reports period=#{@period} threads=#{@threads}") rescue {}

    if @user_ids.any?
      requests = create_requests(@user_ids)
      run_jobs(requests, @threads)
      # create_jobs(requests)
    end

    @slack.post_message("Finished user_ids=#{@user_ids.size} period=#{@period} threads=#{@threads}", thread_ts: @last_response['ts'])
  end

  def create_requests(user_ids)
    max_id = CreatePeriodicReportRequest.maximum(:id) || 0
    requested_by = "batch(#{@period})"

    requests = user_ids.map { |user_id| CreatePeriodicReportRequest.new(user_id: user_id, requested_by: requested_by) }
    requests.each_slice(1000) do |data|
      CreatePeriodicReportRequest.import data, validate: false
    end

    CreatePeriodicReportRequest.where('id > ?', max_id).where(requested_by: requested_by).select(:id, :user_id)
  end

  # Not used
  def create_jobs(requests)
    seconds = (requests.size / 400 + 1) * 60 # Send 400 messages/minute
    requests.each do |request|
      CreatePeriodicReportWorker.perform_in(rand(seconds), request.id, user_id: request.user_id)
    end
  end

  def run_jobs(requests, threads)
    processed_count = 0
    @errors_count = 0
    @lock = Mutex.new

    requests.each_slice(threads) do |group|
      start_time = Time.zone.now

      work_in_threads(group)
      processed_count += group.size

      if (elapsed_time = Time.zone.now - start_time) < 1
        sleep 1.0 - elapsed_time
      end

      if processed_count <= threads || processed_count % 1000 == 0 || processed_count == requests.size
        elapsed = Time.zone.now - @start_time
        avg = elapsed / processed_count
        @last_response = @slack.post_message("Progress total=#{requests.size} processed=#{processed_count}#{" errors=#{@errors_count}" if @errors_count > 0} elapsed=#{sprintf('%.3f', elapsed)} avg=#{sprintf('%.3f', avg)}", thread_ts: @last_response['ts']) rescue nil
      end
    end
  end

  def work_in_threads(requests)
    requests.map do |request|
      Thread.new(request) do |req|
        ActiveRecord::Base.connection_pool.with_connection do
          CreatePeriodicReportWorker.new.perform(req.id, user_id: req.user_id)
        rescue => e
          @lock.synchronize { @errors_count += 1 }
          Airbag.warn "#{self.class}##{__method__}: #{e.inspect}", request_id: req.id
        end
      end
    end.each(&:join)
  end

  class << self
    def periodic_base_user_ids
      user_ids = dm_received_user_ids.uniq
      user_ids = reject_banned_user_ids(user_ids)
      user_ids = (user_ids + premium_user_ids).uniq
      reject_stop_requested_user_ids(user_ids)
    end

    def morning_user_ids
      reject_specific_period_stopped_user_ids(periodic_base_user_ids, :morning)
    end

    def afternoon_user_ids
      reject_specific_period_stopped_user_ids(periodic_base_user_ids, :afternoon)
    end

    def night_user_ids
      periodic_base_user_ids
    end

    def reject_specific_period_stopped_user_ids(user_ids, period_name)
      user_ids.each_slice(1000).each do |user_ids_array|
        settings = PeriodicReportSetting.where(user_id: user_ids_array).where(period_name => false).select(:id, :user_id)
        user_ids -= settings.map(&:user_id)
      end
      user_ids
    end

    def dm_received_user_ids
      uids = DirectMessageReceiveLog.received_sender_ids
      uids.each_slice(1000).map { |uids_array| User.authorized.where(uid: uids_array).pluck(:id) }.flatten
    end

    def premium_user_ids
      User.premium.authorized.pluck(:id)
    end

    def reject_stop_requested_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - StopPeriodicReportRequest.where(user_id: ids).pluck(:user_id)
      end.flatten
    end

    def allotted_messages_will_expire_user_ids
      uids = DirectMessageReceiveLog.received_sender_ids
      users = uids.each_slice(1000).map { |uids_array| User.authorized.where(uid: uids_array).select(:id, :uid) }.flatten
      users.sort_by! { |user| uids.index(user.uid) }

      user_ids = users.select do |user|
        DirectMessageReceiveLog.remaining_time(user.uid) < 3.hours &&
            DirectMessageSendCounter.messages_left?(user.uid)
      end.map(&:id)

      user_ids = reject_stop_requested_user_ids(user_ids)
      user_ids = reject_remind_requested_user_ids(user_ids)
      user_ids = reject_premium_user_ids(user_ids)
      reject_banned_user_ids(user_ids)
    end

    def reject_remind_requested_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - RemindPeriodicReportRequest.where(user_id: ids).pluck(:user_id)
      end.flatten
    end

    def reject_banned_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - BannedUser.where(user_id: ids).pluck(:user_id)
      end.flatten
    end

    def reject_premium_user_ids(user_ids)
      user_ids.each_slice(1000).map do |ids|
        ids - User.premium.where(id: ids).pluck(:id)
      end.flatten
    end
  end
end
