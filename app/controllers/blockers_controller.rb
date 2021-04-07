class BlockersController < ApplicationController

  before_action { head :forbidden if twitter_dm_crawler? }
  before_action { require_login! }

  def index
    unless (@twitter_user = TwitterUser.latest_by(uid: current_user.uid))
      redirect_to timeline_path(current_user, via: current_via)
    end
  end
end
