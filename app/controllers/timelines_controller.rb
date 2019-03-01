class TimelinesController < ApplicationController
  include Concerns::Showable

  before_action only: %i(check_for_updates) do
    uid = params[:uid].to_i
    valid_uid?(uid) && twitter_user_persisted?(uid)  && authorized_search?(TwitterUser.latest_by(uid: uid))
  end

  after_action only: %i(show) do
    Util::SearchCountCache.increment
  end

  def show
    if ForbiddenUser.exists?(screen_name: @twitter_user.screen_name)
      flash.now[:alert] = forbidden_message(@twitter_user.screen_name)
    elsif NotFoundUser.exists?(screen_name: @twitter_user.screen_name)
      flash.now[:alert] = not_found_message(@twitter_user.screen_name)
    end
  end

  def check_for_updates
    twitter_user = TwitterUser.latest_by(uid: params[:uid])
    if params[:created_at].to_s.match(/\A\d+\z/) && twitter_user.created_at > Time.zone.at(params[:created_at].to_i)
      return render json: {found: true, text: changes_text(twitter_user)}
    end

    started_at = (Time.zone.at(params[:started_at].to_i).to_s(:db) rescue '')
    render json: params.slice(:uid, :jid, :interval, :retry_count).merge(started_at: started_at), status: 202
  end

  private

  def changes_text(twitter_user)
    second_latest = TwitterUser.till(twitter_user.created_at).latest_by(uid: params[:uid])

    bef = second_latest.calc_unfollower_uids.size # Heavy process
    aft = twitter_user.unfollowerships.size

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
