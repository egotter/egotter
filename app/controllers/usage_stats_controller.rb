class UsageStatsController < ::Base
  include WorkersHelper
  include TweetTextHelper

  before_action only: %i(check_for_updates) do
    uid = params[:uid].to_i
    valid_uid?(uid) && existing_uid?(uid)  && authorized_search?(TwitterUser.latest(uid))
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

    @jid = enqueue_update_usage_stat_worker_if_needed(@twitter_user.uid.to_i)
  end

  def check_for_updates
    stat = UsageStat.find_by(uid: params[:uid])
    return render json: {found: false}, status: 200 unless stat

    if params[:updated_at] == '-1' ||
        (params[:updated_at].to_s.match(/\A\d+\z/) && stat.updated_at > Time.zone.at(params[:updated_at].to_i))
      return render json: {found: true}, status: 200
    end

    render json: {found: false}, status: 200
  end
end
