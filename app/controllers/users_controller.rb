class UsersController < ApplicationController
  before_action :require_login!

  after_action { CreateTwitterDBUserWorker.perform_async([current_user.uid], user_id: current_user.id, enqueued_by: 'UsersController') }

  def update
    user = fetch_user

    if user
      current_user.update!(screen_name: user[:screen_name])
      render json: {screen_name: current_user.screen_name}
    else
      render json: {error: "Couldn't fetch user."}, status: :bad_request
    end
  end

  private

  def fetch_user
    current_user.api_client.user(current_user.uid)
  rescue Twitter::Error::Unauthorized => e
    unless TwitterApiStatus.unauthorized?(e)
      logger.warn "#{controller_name}##{action_name} #{e.inspect} user_id=#{current_user.id}"
    end
    nil
  end
end
