require 'active_support/concern'

module Concerns::SearchRequestInstrumentationConcern
  extend ActiveSupport::Concern

  included do
    prepend_before_action do
      @search_request_benchmark = {}
      @search_request_start_time = Time.zone.now
    end

    after_action do
      elapsed = Time.zone.now - @search_request_start_time
      @search_request_benchmark[:sum] = @search_request_benchmark.values.sum
      @search_request_benchmark[:elapsed] = elapsed
      logger.info "Benchmark SearchRequest #{controller_name}##{action_name} #{sprintf("%.3f sec", elapsed)}"
      logger.info "Benchmark SearchRequest #{controller_name}##{action_name} #{@search_request_benchmark.inspect}"
    rescue => e
      logger.warn "Internal error during benchmarking. Cause: #{e.inspecct}"
    end
  end

  %i(
    signed_in_user_authorized?
    enough_permission_level?
    valid_screen_name?
    not_found_screen_name?
    forbidden_screen_name?
    build_twitter_user_by
    search_limitation_soft_limited?
    protected_search?
    blocked_search?
    twitter_user_persisted?
    twitter_db_user_persisted?
    too_many_searches?
    too_many_requests?
    set_new_screen_name_if_changed
    enqueue_logging_job
    enqueue_update_authorized
    enqueue_update_egotter_friendship
    enqueue_audience_insight
    find_or_create_chart_builder
  ).each do |method_name|
    define_method(method_name) do |*args, &blk|
      start = Time.zone.now
      ret_val = method(method_name).super_method.call(*args, &blk)

      # In test, this instance variable is not defined
      @search_request_benchmark[method_name] = Time.zone.now - start if @search_request_benchmark
      ret_val
    end
  end
end
