class ResetEgotterController < ApplicationController
  before_action :require_login!

  def reset
    log = ResetEgotterLog.create!(session_id: fingerprint, user_id: current_user.id, uid: current_user.uid, screen_name: current_user.screen_name)
    render json: {reset_egotter_log_id: log.id}
  end
end
