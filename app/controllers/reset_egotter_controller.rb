class ResetEgotterController < ApplicationController
  before_action :require_login!

  before_action do
    if ResetEgotterLog.exists?(user_id: current_user.id, status: false)
      render json: {error: 'Already requested.'}, status: :bad_request
    end
  end

  def reset
    request = ResetEgotterLog.create!(
        session_id: fingerprint,
        user_id: current_user.id,
        uid: current_user.uid,
        screen_name: current_user.screen_name
    )
    jid = ResetEgotterWorker.perform_async(request.id)
    render json: {request_id: request.id, jid: jid}
  end
end
