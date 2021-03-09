class AppStatsController < ApplicationController

  before_action :authenticate_admin!

  def index
    render plain: AppStat.new.to_s
  end
end
