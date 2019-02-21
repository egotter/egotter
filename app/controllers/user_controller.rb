class UserController < ApplicationController
  before_action :require_login!
  before_action :create_search_log

  def update
    t_user = request_context_client.user(current_user.uid)
    current_user.update!(screen_name: t_user[:screen_name])
    TwitterDB::User.import_by!(twitter_user: TwitterUser.build_by(user: t_user))
    render json: {screen_name: current_user.screen_name}
  end
end
