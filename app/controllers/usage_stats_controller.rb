class UsageStatsController < ApplicationController
  include Concerns::SearchRequestConcern
  include Concerns::JobQueueingConcern
  include TweetTextHelper

  before_action only: %i(check_for_updates) do
    uid = params[:uid].to_i
    valid_uid?(uid) && twitter_user_persisted?(uid)  && !protected_search?(TwitterUser.latest_by(uid: uid))
  end

  def show
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name})

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name})

    @stat = UsageStat.find_or_initialize_by(uid: @twitter_user.uid)

    @tweet_text = usage_time_text(@stat.usage_time, @twitter_user)

    unless from_crawler?
      @jid = UpdateUsageStatWorker.perform_async(@twitter_user.uid, enqueued_at: Time.zone.now)
    end
  end

  def check_for_updates
    stat = UsageStat.find_by(uid: params[:uid])
    started_at = (Time.zone.at(params[:started_at].to_i).to_s(:db) rescue '')
    return render json: params.slice(:uid, :jid, :interval, :retry_count).merge(started_at: started_at), status: 202 unless stat

    if params[:updated_at] == '-1' ||
        (params[:updated_at].to_s.match(/\A\d+\z/) && stat.updated_at > Time.zone.at(params[:updated_at].to_i))
      return render json: {found: true}
    end

    render json: params.slice(:uid, :jid, :interval, :retry_count).merge(started_at: started_at), status: 202
  end
end
