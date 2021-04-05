class ErrorPagesController < ApplicationController
  def too_many_searches
  end

  def ad_blocker_detected
  end

  def soft_limited
  end

  def not_found_user
    unless (@screen_name = session.delete(:screen_name))
      redirect_to root_path(via: current_via)
    end
  end

  def forbidden_user
    unless (@screen_name = session.delete(:screen_name))
      redirect_to root_path(via: current_via)
    end
  end
end
