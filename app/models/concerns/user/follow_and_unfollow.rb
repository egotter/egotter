require 'active_support/concern'

module Concerns::User::FollowAndUnfollow
  extend ActiveSupport::Concern

  def create_follow_limit
    if Rails.env.test?
      Rails.configuration.x.constants['basic_plan_follow_requests_limit']
    elsif is_subscribing?
      followers_count = api_client.user(uid)[:followers_count]
      case followers_count
        when 0..99      then 20
        when 100..499   then 30
        when 500..999   then 40
        when 1000..1999 then 50
        when 2000..2999 then 70
        else Rails.configuration.x.constants['basic_plan_follow_requests_limit']
      end
    else
      Rails.configuration.x.constants['anonymous_follow_requests_limit']
    end
  end

  def create_follow_remaining
    create_follow_limit - follow_requests.where(created_at: 1.day.ago..Time.zone.now).size
  end

  def create_follow_remaining?
    create_follow_remaining > 0
  end

  def create_unfollow_limit
    if is_subscribing?
      Rails.configuration.x.constants['basic_plan_unfollow_requests_limit']
    else
      Rails.configuration.x.constants['anonymous_unfollow_requests_limit']
    end
  end

  def create_unfollow_remaining
    create_unfollow_limit - unfollow_requests.where(created_at: 1.day.ago..Time.zone.now).size
  end

  def create_unfollow_remaining?
     create_unfollow_remaining > 0
  end
end