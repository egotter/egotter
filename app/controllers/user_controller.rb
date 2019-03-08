class UserController < ApplicationController
  before_action :require_login!
  before_action :create_search_log

  after_action { CreateTwitterDBUserWorker.perform_async([current_user.uid]) }

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
    unless e.message == 'Invalid or expired token.'
      logger.warn "#{controller_name}##{action_name} #{e.class} #{e.message} #{current_user.id}"
      logger.info e.backtrace.join("\n")
    end
    nil
  end
end
