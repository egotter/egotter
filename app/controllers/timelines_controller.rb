class TimelinesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper
  include WorkersHelper
  include ScoresHelper

  before_action only: %i(check_for_updates) do
    uid = params[:uid].to_i
    valid_uid?(uid) && existing_uid?(uid)  && authorized_search?(TwitterUser.latest(uid))
  end

  before_action(only: %i(show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: %i(show)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: %i(show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end

  before_action only: %i(show) do
    push_referer
    create_search_log
  end

  def show
    if @twitter_user.forbidden_account?
      flash.now[:alert] = forbidden_message(@twitter_user.screen_name)
    else
      @jid = add_create_twitter_user_worker_if_needed(@twitter_user.uid, user_id: current_user_id, screen_name: @twitter_user.screen_name)
    end

    @stat = UsageStat.find_by(uid: @twitter_user.uid)
    @score = find_or_create_score(@twitter_user.uid).klout_score
  end

  def check_for_updates
    @twitter_user = TwitterUser.latest(params[:uid])
    if params[:created_at].match(/\A\d+\z/) && @twitter_user.created_at > Time.zone.at(params[:created_at].to_i)
      return render json: {found: true, text: changes_text(@twitter_user)}, status: 200
    end

    render json: {found: false}, status: 200
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

    if twitter_user.unfollowerships.size > second_latest.unfollowerships.size
      I18n.t('common.show.unfollowerships_count_increased', user: twitter_user.mention_name, before: second_latest.unfollowerships.size, after: twitter_user.unfollowerships.size)
    else
      if twitter_user.followers_count > second_latest.followers_count
        I18n.t('common.show.followers_count_increased', user: twitter_user.mention_name, before: second_latest.followers_count, after: twitter_user.followers_count)
      elsif twitter_user.followers_count < second_latest.followers_count
        I18n.t('common.show.followers_count_decreased', user: twitter_user.mention_name, before: second_latest.followers_count, after: twitter_user.followers_count)
      else
        I18n.t('common.show.update_is_coming', user: twitter_user.mention_name)
      end
    end
  rescue => e
    I18n.t('common.show.update_is_coming', user: twitter_user.mention_name)
  end
end
