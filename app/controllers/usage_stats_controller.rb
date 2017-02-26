class UsageStatsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include ClustersHelper
  include TweetTextHelper

  before_action :reject_crawler, only: %i(create)
  before_action(only: %i(create show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: %i(create show)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: %i(create show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(create show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action only: %i(new create show) do
    if request.format.html?
      push_referer
      create_search_log(action: "#{controller_name}/#{action_name}")
    end
  end

  def new
    @title = t('usage_stats.new.plain_title')
  end

  def create
    redirect_path = usage_stat_path(screen_name: @tu.screen_name)
    if TwitterUser.exists?(uid: @tu.uid)
      redirect_to redirect_path
    else
      @screen_name = @tu.screen_name
      @redirect_path = redirect_path
      @via = params['via']
      render template: 'searches/create', layout: false
    end
  end

  def show
    @usage_stat = UsageStat.update_with_statuses!(@twitter_user.uid, @twitter_user.statuses)
  end
end
