class StartPeriodicReportsCreatingRecordsTask
  # For debugging
  attr_accessor :user_ids

  def initialize(period: nil, threads: nil)
    @period = period || 'none'
    @threads = threads || 30

    if period == 'morning'
      @user_ids = StartPeriodicReportsTask.morning_user_ids
    elsif period == 'afternoon'
      @user_ids = StartPeriodicReportsTask.afternoon_user_ids
    elsif period == 'night'
      @user_ids = StartPeriodicReportsTask.night_user_ids
    end
  end

  def start
    response = SlackBotClient.channel('cron').post_message("Start creating records period=#{@period} threads=#{@threads}") rescue {}

    if @user_ids.any?
      requests = create_requests(@user_ids)
      run_jobs(requests, @threads)
      # create_jobs(requests)
    end

    SlackBotClient.channel('cron').post_message("Finished user_ids=#{@user_ids.size} period=#{@period}  threads=#{@threads}", thread_ts: response['ts']) rescue nil
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

  def run_jobs(requests, threads)
    requests.each_slice(threads) do |partial_requests|
      threads = partial_requests.map do |request|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            CreateReportTwitterUserWorker.new.perform(request.id, period: @period)
          end
        rescue => e
          puts "#{e.inspect} request_id=#{request.id}"
        end
      end
      threads.each(&:join)
    end
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
