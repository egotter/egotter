class UserController < ApplicationController
  before_action :require_login!
  before_action :create_search_log

  def update
    t_user = request_context_client.user(current_user.uid)
    current_user.update!(screen_name: t_user[:screen_name])
    CreateTwitterDBUserWorker.perform_async([current_user.uid])
    render json: {screen_name: current_user.screen_name}
  end
end
