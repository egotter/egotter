class TimelinesController < ApplicationController
  include Concerns::Showable
  include WorkersHelper

  before_action only: %i(check_for_updates) do
    uid = params[:uid].to_i
    valid_uid?(uid) && existing_uid?(uid)  && authorized_search?(TwitterUser.latest(uid))
  end

  def show
    if @twitter_user.forbidden_account?
      flash.now[:alert] = forbidden_message(@twitter_user.screen_name)
    elsif @twitter_user.not_found_account?
      flash.now[:alert] = not_found_message(@twitter_user.screen_name)
    else
      @jid = enqueue_create_twitter_user_job_if_needed(@twitter_user.uid, user_id: current_user_id, screen_name: @twitter_user.screen_name)
    end
  end

  def check_for_updates
    twitter_user = TwitterUser.latest(params[:uid])
    if params[:created_at].to_s.match(/\A\d+\z/) && twitter_user.created_at > Time.zone.at(params[:created_at].to_i)
      return render json: {found: true, text: changes_text(twitter_user)}, status: 200
    end

    started_at = (Time.zone.at(params[:started_at].to_i).to_s(:db) rescue '')
    render json: params.slice(:uid, :jid, :interval, :retry_count).merge(started_at: started_at), status: 202
  end

  def check_for_follow
    if user_signed_in?
      follow = (Bot.api_client.friendship?(current_user.uid.to_i, User::EGOTTER_UID) rescue false)
      render json: {follow: follow}, status: 200
    else
      head :bad_request
    end
  end

  private

  def changes_text(twitter_user)
    second_latest = TwitterUser.till(twitter_user.created_at).latest(params[:uid])

    bef = second_latest.unfollowerships.size # Heavy process
    aft = twitter_user.twitter_db_user.unfollowerships.size

    if aft > bef
      t('.unfollowerships_count_increased', user: twitter_user.mention_name, before: bef, after: aft)
    else
      if twitter_user.followers_count > second_latest.followers_count
        t('.followers_count_increased', user: twitter_user.mention_name, before: second_latest.followers_count, after: twitter_user.followers_count)
      elsif twitter_user.followers_count < second_latest.followers_count
        t('.followers_count_decreased', user: twitter_user.mention_name, before: second_latest.followers_count, after: twitter_user.followers_count)
      elsif twitter_user.friends_count > second_latest.friends_count
        t('.friends_count_increased', user: twitter_user.mention_name, before: second_latest.friends_count, after: twitter_user.friends_count)
      elsif twitter_user.friends_count < second_latest.friends_count
        t('.friends_count_decreased', user: twitter_user.mention_name, before: second_latest.friends_count, after: twitter_user.friends_count)
      else
        I18n.t('common.show.update_is_coming', user: twitter_user.mention_name)
      end
    end
  rescue => e
    I18n.t('common.show.update_is_coming', user: twitter_user.mention_name)
  end
end
