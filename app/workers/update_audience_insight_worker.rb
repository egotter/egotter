class UpdateAudienceInsightWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(uid, options = {})
    uid
  end

  def unique_in
    3.minute
  end

  # Handle timeout by myself
  def _timeout_in
    10.seconds
  end

  def after_timeout(*args)
    logger.info { "Timeout seconds=#{_timeout_in} args=#{args.inspect}" }
    UpdateAudienceInsightWorker.perform_in(retry_in, *args)
  end

  def retry_in
    unique_in + rand(120)
  end

  def expire_in
    10.minute
  end

  # options:
  #   location
  #   twitter_user_id
  def perform(uid, options = {})
    insight = AudienceInsight.find_or_initialize_by(uid: uid) # TODO Select only specific columns
    return if insight.fresh?

    chart_builder = nil
    bm('Builder.new') do
      chart_builder = AudienceInsightChartBuilder.new(uid, limit: 100)
    end

    records = []
    bm('CacheLoader.load') do
      # This code might break the sidekiq process which is processing UpdateAudienceInsightWorker
      records = chart_builder.builder.users
      loader = CacheLoader.new(records, timeout: _timeout_in, concurrency: 1) do |record|
        record.friend_uids
        record.follower_uids
      end
      loader.load
    rescue CacheLoader::Timeout => e
      after_timeout(uid, {'records.size' => records.size}.merge(options))
      return
    end

    AudienceInsight::CHART_NAMES.each do |chart_name|
      bm(chart_name) do
        insight.send("#{chart_name}_text=", chart_builder.send(chart_name).to_json)
      end
    end

    bm('save!') { insight.save! if insight.changed? }

  rescue => e
    handle_exception(e, uid, options)
  end

  def handle_exception(e, uid, options)
    if e.class == ActiveRecord::RecordNotUnique
      return
    end

    logger.warn "#{e.inspect} uid=#{uid} options=#{options}"
    logger.info e.backtrace.join("\n")
  end

  module Instrumentation
    def bm(message, &block)
      start = Time.zone.now
      yield
      @benchmark[message] = Time.zone.now - start
    end

    def perform(*args, &blk)
      @benchmark = {}
      start = Time.zone.now

      super

      @benchmark['sum'] = @benchmark.values.sum
      @benchmark['elapsed'] = Time.zone.now - start
      logger.info "Benchmark UpdateAudienceInsightWorker #{@benchmark.inspect}"
    end
  end
  prepend Instrumentation
end
