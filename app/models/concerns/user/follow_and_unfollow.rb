require 'active_support/concern'

module Concerns::User::FollowAndUnfollow
  extend ActiveSupport::Concern

  def create_follow_limit
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

  def can_create_follow?
    FollowRequest.finished(id).where(finished_at: 1.day.ago..Time.zone.now).size < create_follow_limit
  end

  def create_unfollow_limit
    20
  end

  def can_create_unfollow?
    UnfollowRequest.finished(id).where(finished_at: 1.day.ago..Time.zone.now).size < create_unfollow_limit
  end
end