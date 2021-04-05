class ErrorPagesController < ApplicationController
  before_action :set_screen_name, only: %i(too_many_searches soft_limited not_found_user forbidden_user)

  def too_many_searches
  end

  def ad_blocker_detected
  end

  def soft_limited
  end

  def not_found_user
  end

  def forbidden_user
  end

  private

  def set_screen_name
    unless (@screen_name = session.delete(:screen_name))
      redirect_to root_path(via: current_via)
    end
  end
end
