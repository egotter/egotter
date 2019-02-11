require 'active_support/concern'

module Concerns::Request::FollowAndUnfollow
  extend ActiveSupport::Concern

  included do
    scope :without_error, -> do
      sql = <<~SQL
        error_message is null
        or error_message = ''
        or error_message like 'You are unable to follow more people at this time.%'
        or error_message like 'Follow or unfollow limit exceeded%'
      SQL
      where(sql)
    end

    # Don't include 'Follow or unfollow limit exceeded' as using to check perform_limit_reset_at
    # TODO To change the query for UnfollowRequest
    scope :with_limit_error, -> {where("error_message like 'You are unable to follow more people at this time.%'")}

    scope :unprocessed, -> user_id {
      where(user_id: user_id, finished_at: nil).
          where.not(uid: User::EGOTTER_UID).
          where(created_at: 1.day.ago..Time.zone.now).
          without_error
    }

    scope :finished, -> user_id {
      where(user_id: user_id).
          where.not(finished_at: nil)
    }
  end

  def finished!
    update!(finished_at: Time.zone.now) if finished_at.nil?
  end

  class_methods do
    def next_request(user_id)
      unprocessed(user_id).order(created_at: :asc).first
    end

    def collect_follow_or_unfollow_sidekiq_jobs(name, user_id)
      Sidekiq::ScheduledSet.new.select {|job| job.klass == name && job.args[0] == user_id} +
          Sidekiq::Queue.new(name).select {|job| job.klass == name && job.args[0] == user_id}
    end

    def current_interval
      global_can_perform? ? short_limit_interval : long_limit_interval
    end

    def global_can_perform?
      perform_limit_reset_at < Time.zone.now
    end

    def perform_limit_reset_at
      last_error_time = with_limit_error.order(updated_at: :desc).pluck(:updated_at).first
      last_error_time.nil? ? 1.second.ago : last_error_time + long_limit_interval
    end

    def short_limit_interval
      30.seconds
    end

    def long_limit_interval
      30.minutes
    end
  end
end
