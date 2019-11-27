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
    twitter_user = TwitterUser.latest_by(uid: @twitter_user.uid)
    unless twitter_user
      return render json: {found: false}.merge(echo_back_params), status: :not_found
    end

    starting_time = params[:created_at].to_s.match?(/\A\d+\z/) ? Time.zone.at(params[:created_at].to_i) : nil

    # Use '<' instead of '<='.
    #   On waiting page
    #     params[:created_at] means the time when polling was started.
    #   On background-update page
    #     params[:created_at] means the time when the latest record was created.
    #
    if starting_time.nil? || starting_time < twitter_user.created_at
      render json: {found: true, created_at: twitter_user.created_at.to_i, text: create_changes_text(twitter_user)}
    else
      render json: {found: false, started_at: starting_time.to_s(:db)}.merge(echo_back_params), status: :accepted
    end
  end

  private

  def echo_back_params
    params.permit(:uid, :jid, :interval, :retry_count)
  end

  def create_changes_text(twitter_user)
    seconds = 2.seconds
    Timeout.timeout(seconds) do
      ChangesTextBuilder.new(twitter_user).build
    end
  rescue Timeout::Error => e
    logger.info "#{controller_name}##{__method__} The request has timed out. (#{seconds.inspect}) #{e.class} #{e.message} #{twitter_user.id}"
    logger.info e.backtrace.join("\n")
    I18n.t('twitter_users.show.update_is_coming_with_timeout', user: twitter_user.mention_name)
  end

  class ChangesTextBuilder
    attr_reader :current_twitter_user, :previous_twitter_user, :screen_name

    def initialize(current_twitter_user)
      @current_twitter_user = current_twitter_user
      @previous_twitter_user = TwitterUser.where('created_at < ?', current_twitter_user.created_at).order(created_at: :desc).find_by(uid: current_twitter_user.uid)
      @screen_name = current_twitter_user.screen_name
    end

    def build
      unless previous_twitter_user
        return I18n.t('twitter_users.show.new_record_created', user: screen_name)
      end

      previous_size = previous_twitter_user.calc_unfollower_uids.size
      current_size = current_twitter_user.unfollowerships.size

      # TODO At this point, the import batch may not be finished yet.

      if current_size > previous_size
        I18n.t('twitter_users.show.unfollowerships_count_increased', user: screen_name, before: previous_size, after: current_size)
      elsif current_size < previous_size
        I18n.t('twitter_users.show.unfollowerships_count_changed', user: screen_name)
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
