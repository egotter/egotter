class TwitterUsersController < ApplicationController
  include JobQueueingConcern

  before_action :reject_crawler
  before_action :require_login!
  before_action { valid_uid?(params[:uid]) }
  before_action { head :forbidden unless SearchRequest.request_for(current_user.id, uid: params[:uid]) }
  before_action { @twitter_user = TwitterUser.latest_by(uid: params[:uid]) }

  # Polling access of waiting
  # Polling access of background-update
  def show
    twitter_user = TwitterUser.with_delay.latest_by(uid: params[:uid])
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

      # To save time, only the latest differences are calculated.
      new_unfollower_uids = UnfriendsBuilder::Util.unfollowers(previous_twitter_user, current_twitter_user)

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
      Airbag.warn "#{self.class}##{__method__} #{e.inspect} #{previous_twitter_user&.id} #{current_twitter_user.id}"
      Airbag.info e.backtrace.join("\n")
      I18n.t('twitter_users.show.update_is_coming_with_error', user: screen_name)
    end
  end
end
