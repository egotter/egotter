require 'active_support/concern'

module Concerns::User::FollowAndUnfollow
  extend ActiveSupport::Concern

  def create_follow_limit
    if Rails.env.test?
      100
    else
      followers_count = api_client.user(uid)[:followers_count]
      case followers_count
        when 0..99      then 20
        when 100..499   then 30
        when 500..999   then 40
        when 1000..1999 then 50
        when 2000..2999 then 70
        else 100
      end
    end
  end

  def can_create_follow?
    FollowRequest.finished(id).where(finished_at: 1.day.ago..Time.zone.now).size < create_follow_limit
  end

  def create_unfollow_limit
    20
  end

  def can_create_unfollow?
    UnfollowRequest.finished(id).where(finished_at: 1.day.ago..Time.zone.now).size < create_unfollow_limit
  end

  module Util
    module_function

    def global_can_create_follow?
      follow_limit_reset_at < Time.zone.now
    end

    def follow_limit_reset_at
      last_error_time = ::FollowRequest.with_limit_error.order(updated_at: :desc).pluck(:updated_at).first
      last_error_time.nil? ? 1.second.ago : last_error_time + limit_interval
    end

    def global_can_create_unfollow?
      unfollow_limit_reset_at < Time.zone.now
    end

    def unfollow_limit_reset_at
      last_error_time = ::UnfollowRequest.with_limit_error.order(updated_at: :desc).pluck(:updated_at).first
      last_error_time.nil? ? 1.second.ago : last_error_time + limit_interval
    end

    def limit_interval
      30.minutes
    end

    def collect_follow_or_unfollow_sidekiq_jobs(name, user_id)
      Sidekiq::ScheduledSet.new.select {|job| job.klass == name && job.args[0] == user_id} +
          Sidekiq::Queue.new(name).select {|job| job.klass == name && job.args[0] == user_id}
    end
  end
end