require 'active_support/concern'

module TwitterUsersConcern
  extend ActiveSupport::Concern

  included do
  end

  def build_twitter_user_by(screen_name:)
    user = request_context_client.user(screen_name)
    TwitterUser.build_by(user: user)
  rescue => e
    handle_twitter_api_error(e, __method__)
    nil
  end

  def build_twitter_user_by_uid(uid)
    screen_name = request_context_client.user(uid.to_i)[:screen_name]
    build_twitter_user_by(screen_name: screen_name)
  rescue => e
    handle_twitter_api_error(e, __method__)
    nil
  end

  private

  def handle_twitter_api_error(e, location)
    via = current_via(location)

    if TwitterApiStatus.not_found?(e)
      redirect_to error_pages_twitter_error_not_found_path(via: via)
    elsif TwitterApiStatus.suspended?(e)
      redirect_to error_pages_twitter_error_suspended_path(via: via)
    elsif TwitterApiStatus.unauthorized?(e)
      redirect_to error_pages_twitter_error_unauthorized_path(via: via)
    elsif TwitterApiStatus.temporarily_locked?(e)
      redirect_to error_pages_twitter_error_temporarily_locked_path(via: via)
    else
      redirect_to error_pages_twitter_error_unknown_path(via: via)
    end
  end
end
