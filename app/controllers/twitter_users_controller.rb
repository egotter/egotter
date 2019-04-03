class TwitterUsersController < ApplicationController
  include Concerns::JobQueueingConcern

  before_action :reject_crawler
  before_action { valid_uid?(params[:uid]) }
  before_action { @twitter_user = build_twitter_user_by_uid(params[:uid]) }
  before_action { authorized_search?(@twitter_user) && !blocked_search?(@twitter_user) }
  before_action { !too_many_searches?(@twitter_user) && !too_many_requests?(@twitter_user) }

  before_action { create_search_log }

  def create
    jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id, screen_name: @twitter_user.screen_name)
    render json: {uid: @twitter_user.uid, screen_name: @twitter_user.screen_name, jid: jid}
  end

  def show
    twitter_user = TwitterUser.latest_by(uid: @twitter_user.uid)
    unless twitter_user
      return render json: {found: false}.merge(echo_back_params), status: :not_found
    end

    started_at = params[:created_at].to_s.match?(/\A\d+\z/) ? Time.zone.at(params[:created_at].to_i) : nil

    if started_at.nil? || started_at < twitter_user.created_at
      render json: {found: true, created_at: twitter_user.created_at.to_i, text: create_changes_text(twitter_user)}
    else
      render json: {found: false, started_at: started_at.to_s(:db)}.merge(echo_back_params), status: :accepted
    end
  end

  private

  def echo_back_params
    params.permit(:uid, :jid, :interval, :retry_count)
  end

  def create_changes_text(twitter_user)
    Timeout.timeout(2.seconds) do
      changes_text(twitter_user)
    end
  rescue Timeout::Error => e
    logger.info "#{controller_name}##{__method__} #{e.class} #{e.message} #{twitter_user.inspect}"
    logger.info e.backtrace.join("\n")
    I18n.t('twitter_users.show.update_is_coming', user: twitter_user.mention_name)
  end

  def changes_text(twitter_user)
    second_latest = TwitterUser.till(twitter_user.created_at).latest_by(uid: params[:uid])

    bef = nil
    benchmark("#{controller_name}##{__method__} #{twitter_user.inspect}", level: :info) do
      bef = second_latest.calc_unfollower_uids.size # Heavy process
    end

    aft = twitter_user.unfollowerships.size

    if aft > bef
      t('twitter_users.show.unfollowerships_count_increased', user: twitter_user.mention_name, before: bef, after: aft)
    else
      if twitter_user.followers_count > second_latest.followers_count
        t('twitter_users.show.followers_count_increased', user: twitter_user.mention_name, before: second_latest.followers_count, after: twitter_user.followers_count)
      elsif twitter_user.followers_count < second_latest.followers_count
        t('twitter_users.show.followers_count_decreased', user: twitter_user.mention_name, before: second_latest.followers_count, after: twitter_user.followers_count)
      elsif twitter_user.friends_count > second_latest.friends_count
        t('twitter_users.show.friends_count_increased', user: twitter_user.mention_name, before: second_latest.friends_count, after: twitter_user.friends_count)
      elsif twitter_user.friends_count < second_latest.friends_count
        t('twitter_users.show.friends_count_decreased', user: twitter_user.mention_name, before: second_latest.friends_count, after: twitter_user.friends_count)
      else
        I18n.t('twitter_users.show.update_is_coming', user: twitter_user.mention_name)
      end
    end
  rescue => e
    I18n.t('twitter_users.show.update_is_coming', user: twitter_user.mention_name)
  end
end
