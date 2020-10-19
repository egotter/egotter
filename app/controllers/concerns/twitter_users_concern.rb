require 'active_support/concern'

module TwitterUsersConcern
  extend ActiveSupport::Concern

  included do
  end

  # Normally you will not be redirected to not_found_path or forbidden_path here.
  # See also #not_found_user? in #not_found_screen_name? or #forbidden_user? in #forbidden_screen_name?
  def build_twitter_user_by(screen_name:)
    user = request_context_client.user(screen_name)
    ::TwitterUser.build_by(user: user)
  rescue => e
    handle_twitter_api_error(e, screen_name)
    nil
  end

  def handle_twitter_api_error(e, screen_name)
    if AccountStatus.not_found?(e)
      redirect_to profile_path(screen_name: screen_name, via: current_via('not_found'))
    elsif AccountStatus.suspended?(e)
      redirect_to profile_path(screen_name: screen_name, via: current_via('suspended'))
    elsif AccountStatus.invalid_or_expired_token?(e)
      respond_with_error(:bad_request, unauthorized_message)
    elsif AccountStatus.temporarily_locked?(e)
      respond_with_error(:bad_request, temporarily_locked_message)
    else
      respond_with_error(:bad_request, twitter_exception_messages(e, screen_name))
      logger.info "#{__method__}: #{e.inspect} controller=#{controller_name} action=#{action_name} screen_name=#{screen_name} user_id=#{current_user&.id}}"
    end
  end

  def build_twitter_user_by_uid(uid)
    screen_name = request_context_client.user(uid.to_i)[:screen_name]
    build_twitter_user_by(screen_name: screen_name)
  rescue => e
    if !AccountStatus.suspended?(e) && !AccountStatus.not_found?(e) && !AccountStatus.unauthorized?(e)
      logger.warn "#{self.class}##{action_name} in #build_twitter_user_by_uid #{e.inspect} uid=#{uid} user_id=#{current_user_id}}"
    end

    respond_with_error(:bad_request, twitter_exception_messages(e, "ID #{uid}"))
    nil
  end
end
