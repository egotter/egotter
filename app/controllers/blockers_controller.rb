class BlockersController < ApplicationController

  before_action { head :forbidden if twitter_dm_crawler? }
  before_action { signed_in_user_authorized? }
  before_action { current_user_has_dm_permission? }

  def index
    @twitter_user = TwitterDB::User.find_by(uid: current_user.uid)
  end
end
