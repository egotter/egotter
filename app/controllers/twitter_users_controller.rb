class TwitterUsersController < ApplicationController
  include JobQueueingConcern

  before_action :reject_crawler
  before_action :require_login!
  before_action { valid_uid?(params[:uid]) }
  before_action :validate_search_request_by_uid!
  before_action { @twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid]) }

  # Polling access of waiting
  # Polling access of background-update
  def show
    twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid])
    render json: {uid: params[:uid].to_s, created_at: twitter_user&.created_at&.to_i}
  end

  def changes
    twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid])
    render json: {text: changes_text(twitter_user)}
  end

  private

  def changes_text(twitter_user)
    unless twitter_user
      return t('.changes.new_record_created', user: twitter_user.screen_name)
    end

    previous_version = twitter_user.previous_version

    unless previous_version
      return t('.changes.new_record_created', user: twitter_user.screen_name)
    end

    if (uids = twitter_user.calc_new_unfollower_uids).any?
      return t('.changes.unfollowers_changed', user: twitter_user.screen_name, count: uids.size)
    end

    options = {
        user: twitter_user.screen_name,
        previous_friends: previous_version.friends_count,
        current_friends: twitter_user.friends_count,
        previous_followers: previous_version.followers_count,
        current_followers: twitter_user.followers_count,
    }

    if twitter_user.followers_count > previous_version.followers_count
      t('.changes.followers_increased', options)
    elsif twitter_user.followers_count < previous_version.followers_count
      t('.changes.followers_decreased', options)
    elsif twitter_user.friends_count > previous_version.friends_count
      t('.changes.friends_increased', options)
    elsif twitter_user.friends_count < previous_version.friends_count
      t('.changes.friends_decreased', options)
    else
      t('.changes.something_changed', options)
    end
  rescue => e
    Airbag.warn "#{self.class}##{__method__} #{e.inspect} twitter_user_id=#{twitter_user.id}"
    t('.changes.error', user: twitter_user.screen_name)
  end
end
