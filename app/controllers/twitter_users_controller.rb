class TwitterUsersController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :reject_crawler
  before_action { valid_uid?(params[:uid]) }
  before_action { @twitter_user = build_twitter_user_by_uid(params[:uid]) }
  before_action { !protected_search?(@twitter_user) && !blocked_search?(@twitter_user) }
  before_action { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) }

  before_action { create_search_log }

  # First access of background-update
  def create
    jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id, requested_by: 'background')
    render json: {uid: @twitter_user.uid, screen_name: @twitter_user.screen_name, jid: jid}
  end

  # Polling access of waiting
  # Polling access of background-update
  def show
    twitter_user = TwitterUser.latest_by(uid: params[:uid])
    render json: {uid: params[:uid].to_s, created_at: twitter_user&.created_at&.to_i}
  end

  def changes
    render json: {text: ChangesTextBuilder.new(params[:uid]).build}
  end

  private

  class ChangesTextBuilder
    attr_reader :current_twitter_user, :previous_twitter_user, :screen_name

    def initialize(uid)
      @current_twitter_user = TwitterUser.latest_by(uid: uid)
      @previous_twitter_user = TwitterUser.where.not(id: @current_twitter_user.id).latest_by(uid: uid)
      @screen_name = current_twitter_user.screen_name
    end

    def build
      unless previous_twitter_user
        return I18n.t('twitter_users.show.new_record_created', user: screen_name)
      end

      new_unfollower_uids = []
      begin
        seconds = 2.seconds
        Timeout.timeout(seconds) do
          # To save time, only the latest differences are calculated.
          new_unfollower_uids = UnfriendsBuilder::Util.unfollowers(previous_twitter_user, current_twitter_user)
        end
      rescue Timeout::Error => e
        logger.info "#{self.class}##{__method__} The request has timed out. (#{seconds.inspect}) #{e.class} #{e.message} #{previous_twitter_user.id} #{current_twitter_user.id}"
        logger.info e.backtrace.join("\n")
        return I18n.t('twitter_users.show.update_is_coming_with_timeout', user: screen_name)
      end

      # TODO At this point, the import batch may not be finished yet.

      if new_unfollower_uids.any?
        I18n.t('twitter_users.show.new_unfollowers_are_coming', user: screen_name, count: new_unfollower_uids.size)
      else
        if current_twitter_user.followers_count > previous_twitter_user.followers_count
          I18n.t('twitter_users.show.followers_count_increased', user: screen_name, before: previous_twitter_user.followers_count, after: current_twitter_user.followers_count)
        elsif current_twitter_user.followers_count < previous_twitter_user.followers_count
          I18n.t('twitter_users.show.followers_count_decreased', user: screen_name, before: previous_twitter_user.followers_count, after: current_twitter_user.followers_count)
        elsif current_twitter_user.friends_count > previous_twitter_user.friends_count
          I18n.t('twitter_users.show.friends_count_increased', user: screen_name, before: previous_twitter_user.friends_count, after: current_twitter_user.friends_count)
        elsif current_twitter_user.friends_count < previous_twitter_user.friends_count
          I18n.t('twitter_users.show.friends_count_decreased', user: screen_name, before: previous_twitter_user.friends_count, after: current_twitter_user.friends_count)
        else
          I18n.t('twitter_users.show.update_is_coming', user: screen_name)
        end
      end
    rescue => e
      Rails.logger.warn "#{self.class}##{__method__} #{e.inspect} #{previous_twitter_user&.id} #{current_twitter_user.id}"
      Rails.logger.info e.backtrace.join("\n")
      I18n.t('twitter_users.show.update_is_coming_with_error', user: screen_name)
    end
  end
end
