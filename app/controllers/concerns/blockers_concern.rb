require 'active_support/concern'

module BlockersConcern
  extend ActiveSupport::Concern

  def authenticate_user!
    unless user_signed_in?
      redirect_to error_pages_blockers_not_permitted_path(via: current_via)
    end
  end

  def search_yourself!
    if current_user.uid != @twitter_user.uid
      redirect_to error_pages_blockers_not_permitted_path(via: current_via)
    end
  end

  def has_subscription!
    if !current_user.has_valid_subscription? || current_user.has_trial_subscription?
      redirect_to error_pages_blockers_not_permitted_path(via: current_via)
    end
  end
end
