class StartPeriodicReportsCreatingRecordsTask
  def initialize(period:)
    @period = period || 'none'

    if period == 'morning'
      @user_ids = StartPeriodicReportsTask.morning_user_ids
    elsif period == 'afternoon'
      @user_ids = StartPeriodicReportsTask.afternoon_user_ids
    elsif period == 'night'
      @user_ids = StartPeriodicReportsTask.night_user_ids
    end
  end

  def start!
    response = SlackBotClient.channel('cron').post_message("Start creating records period=#{@period}") rescue {}

    if @user_ids.any?
      requests = create_requests(@user_ids)
      create_jobs(requests)
    end

    SlackBotClient.channel('cron').post_message("Finished user_ids=#{@user_ids.size} period=#{@period}", thread_ts: response['ts']) rescue nil
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

  def create_jobs(requests)
    requests.each do |request|
      CreateReportTwitterUserWorker.perform_async(request.id, period: @period)
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
