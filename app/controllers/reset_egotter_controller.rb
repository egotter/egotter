# TODO Move to Api::V1 module
class ResetEgotterController < ApplicationController
  before_action :require_login!

  before_action do
    if current_user.reset_egotter_requests.not_finished.exists?
      render json: {error: true, message: 'Already requested'}, status: :bad_request
    end
  end

  def reset
    request = ResetEgotterRequest.create!(
        session_id: egotter_visit_id,
        user_id: current_user.id
    )
    ResetEgotterWorker.perform_async(request.id)
    SendResetEgotterStartedWorker.perform_async(request.id)
    render json: {message: 'Reset is requested'}
  end
end
