class StartSendingPromptReportsWorker
  include Sidekiq::Worker
  include Concerns::AirbrakeErrorHandler
  sidekiq_options queue: self, retry: 0, backtrace: false

  def unique_key(*args)
    -1
  end

  def unique_in
    1.minute
  end

  def after_skip
    logger.warn "The job execution is skipped."
  end

  def timeout_in
    120.minutes
  end

  def after_timeout
    logger.warn "The job execution is timed out."
  end

  # options:
  #   last_queueing_started_at
  def perform(options = {})
    if CallCreateDirectMessageEventCount.rate_limited?
      time = CallCreateDirectMessageEventCount.raised_ttl.seconds
      logger.warn "Creating a direct message is rate limited. Wait for #{time.inspect}."
      StartSendingPromptReportsWorker.perform_in(time, options)
      return
    end

    if queueing_interval_too_short?(options)
      wait_time = next_wait_time(options['last_queueing_started_at'])
      logger.warn "Interval is too short. Wait for #{wait_time.inspect}."
      StartSendingPromptReportsWorker.perform_in(wait_time, options)
      return
    end

    start_queueing

  rescue => e
    notify_airbrake(e, options: options)
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  # private

  def queueing_interval_too_short?(options)
    if next_wait_time(options['last_queueing_started_at']) > 0
      true
    else
      false
    end
  end

  QUEUEING_INTERVAL = CreatePromptReportRequest::PROCESS_REQUEST_INTERVAL

  def next_wait_time(previous_started_at)
    if previous_started_at.nil?
      -1
    else
      started_at = Time.zone.parse(previous_started_at)
      interval = Time.zone.now - started_at
      wait_time = QUEUEING_INTERVAL - interval
      wait_time = unique_in + 1.second if 0 < wait_time && wait_time < unique_in
      wait_time
    end
  end

  def start_queueing
    task = StartSendingPromptReportsTask.new

    log = StartSendingPromptReportsLog.create(started_at: Time.zone.now)
    log.update(properties: task.ids_stats)

    requests = create_requests(task.users)
    enqueue_requests(requests, log.started_at)

    log.update(finished_at: Time.zone.now)
  end

  def create_requests(users)
    last_created_at = CreatePromptReportRequest.maximum(:created_at)
    last_created_at = Time.zone.now - 1 unless last_created_at

    requests = users.map { |user| CreatePromptReportRequest.new(user_id: user.id) }
    CreatePromptReportRequest.import requests, validate: false
    CreatePromptReportRequest.where('created_at > ?', last_created_at).order(id: :asc)
  end

  def enqueue_requests(requests, started_at)
    requests.each.with_index do |request, i|
      options = {user_id: request.user_id, index: i}

      if requests.last.id == request.id
        options[:start_next_loop] = true
        options[:queueing_started_at] = started_at
      end

      CreatePromptReportWorker.perform_async(request.id, options)
    end
  end

  module Instrumentation
    def start_queueing(*args, &blk)
      @benchmark = {}
      start = Time.zone.now
      result = super
      @benchmark['Total'] = Time.zone.now - start
      Rails.logger.info "Benchmark StartSendingPromptReportsWorker #{@benchmark.inspect}"
      result
    end

    def create_requests(*args, &blk)
      start = Time.zone.now
      result = super
      @benchmark ||= {}
      @benchmark['create_requests'] = Time.zone.now - start
      result
    end

    def enqueue_requests(*args, &blk)
      start = Time.zone.now
      result = super
      @benchmark ||= {}
      @benchmark['enqueue_requests'] = Time.zone.now - start
      result
    end
  end
  prepend Instrumentation
end
