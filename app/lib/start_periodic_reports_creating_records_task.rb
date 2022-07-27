class StartPeriodicReportsCreatingRecordsTask
  # For debugging
  attr_accessor :user_ids

  def initialize(period: nil, user_ids: nil, threads: nil)
    @period = period || 'none'
    @threads = threads || 20
    @timeout = 3.hours

    if user_ids.present?
      @user_ids = user_ids
    elsif period == 'morning'
      @user_ids = StartPeriodicReportsTask.morning_user_ids
    elsif period == 'afternoon'
      @user_ids = StartPeriodicReportsTask.afternoon_user_ids
    elsif period == 'night'
      @user_ids = StartPeriodicReportsTask.night_user_ids
    end

    @slack = SlackBotClient.channel('cron')
    @last_response = {}
  end

  def start
    @start_time = Time.zone.now
    @last_response = @slack.post_message("Start creating records period=#{@period} threads=#{@threads}") rescue {}

    if @user_ids.any?
      requests = create_requests(@user_ids)
      run_jobs(requests, @threads)
      # create_jobs(requests)
    end

    @slack.post_message("Finished user_ids=#{@user_ids.size} period=#{@period} threads=#{@threads}", thread_ts: @last_response['ts']) rescue nil
    nil
  end

  def create_requests(user_ids)
    max_id = CreateTwitterUserRequest.maximum(:id) || 0
    requested_by = "batch(#{@period})"

    user_ids.each_slice(1000) do |ids_array|
      requests = User.where(id: ids_array).select(:id, :uid).map do |user|
        CreateTwitterUserRequest.new(
            requested_by: requested_by,
            user_id: user.id,
            uid: user.uid)
      end

      CreateTwitterUserRequest.import requests, validate: false
    end

    CreateTwitterUserRequest.where('id > ?', max_id).where(requested_by: requested_by).select(:id, :user_id)
  end

  # Not used
  def create_jobs(requests)
    requests.each do |request|
      CreateReportTwitterUserWorker.perform_async(request.id, period: @period)
    end
  end

  def run_jobs(requests, threads, &block)
    stopped = false
    sigint = Sigint.new.trap do
      stopped = true
      @last_response = @slack.post_message('Stop requested', thread_ts: @last_response['ts']) rescue {}
    end
    processed_count = 0
    @errors_count = 0
    @lock = Mutex.new

    requests.each_slice(threads) do |group|
      if stopped || sigint.trapped?
        CreateTwitterUserRequest.where(id: group.map(&:id)).update_all(status_message: 'Stop requested', failed_at: Time.zone.now)
        next
      end

      if timeout?
        CreateTwitterUserRequest.where(id: group.map(&:id)).update_all(status_message: 'Timeout', failed_at: Time.zone.now)
        next
      end

      work_in_threads(group, @period)
      processed_count += group.size

      if processed_count <= threads || processed_count % 1000 == 0 || processed_count == requests.size
        @last_response = @slack.post_message("Progress #{format_progress(requests.size, processed_count, @errors_count, @start_time)}", thread_ts: @last_response['ts']) rescue nil
      end
    end

    if timeout?
      @last_response = @slack.post_message("Timeout #{format_progress(requests.size, processed_count, @errors_count, @start_time)}", thread_ts: @last_response['ts']) rescue {}
    end
  end

  def work_in_threads(requests, period)
    requests.map do |request|
      Thread.new(request, period) do |req, p|
        # TODO Remove this line?
        ActiveRecord::Base.connection_pool.with_connection do
          CreateReportTwitterUserWorker.new.perform(req.id, 'period' => p)
        rescue => e
          @lock.synchronize { @errors_count += 1 }
          Airbag.warn "#{self.class}##{__method__}: #{e.inspect}", request_id: req.id
        end
      end
    end.each(&:join)
  end

  def timeout?
    @timeout && @start_time && Time.zone.now - @start_time > @timeout
  end

  def format_progress(total, processed, errors, started)
    elapsed = Time.zone.now - started
    avg = elapsed / processed
    "total=#{total} processed=#{processed}#{" errors=#{errors}" if errors > 0} elapsed=#{sprintf('%.3f', elapsed)} avg=#{sprintf('%.3f', avg)}"
  end

  class << self
    def delete_scheduled_jobs
      ss = Sidekiq::ScheduledSet.new
      jobs = ss.scan('CreateReportTwitterUserWorker').select { |job| job.klass == 'CreateReportTwitterUserWorker' }
      jobs.each(&:delete)
      jobs.size
    end
  end
end
