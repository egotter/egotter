require 'active_support/concern'

module Concerns::TwitterUsersConcern
  extend ActiveSupport::Concern

  included do
  end

  # Normally you will not be redirected to not_found_path or forbidden_path here.
  # See also #not_found_user? in #not_found_screen_name? or #forbidden_user? in #forbidden_screen_name?
  def build_twitter_user_by(screen_name:)
    user = request_context_client.user(screen_name)
    twitter_user = TwitterUser.build_by(user: user)

    DeleteNotFoundUserWorker.perform_async(screen_name)
    DeleteForbiddenUserWorker.perform_async(screen_name)

    twitter_user
  rescue => e
    status = AccountStatus.new(ex: e)

    if status.not_found?
      CreateNotFoundUserWorker.perform_async(screen_name)
      redirect_to not_found_path(screen_name: screen_name)
    elsif status.suspended?
      CreateForbiddenUserWorker.perform_async(screen_name)
      redirect_to forbidden_path(screen_name: screen_name)
    else
      logger.info "#{self.class}##{__method__} Something error in #build_twitter_user_by #{e.class} #{e.message}}"
      logger.info e.backtrace.join("\n")

      respond_with_error(:bad_request, twitter_exception_messages(e, screen_name))
    end
  end

  def build_twitter_user_by_uid(uid)
    screen_name = request_context_client.user(uid.to_i)[:screen_name]
    build_twitter_user_by(screen_name: screen_name)
  rescue => e
    respond_with_error(:bad_request, twitter_exception_messages(e, "ID #{uid}"))
  end
end
