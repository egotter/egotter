class AccessStatsController < ApplicationController

  before_action :authenticate_admin!

  layout false

  def index
    @total = CloudWatchClient.new.get_active_users.to_i
    @mobile = CloudWatchClient.new.get_active_users('MOBILE').to_i
    @desktop = CloudWatchClient.new.get_active_users('DESKTOP').to_i
  end
end
