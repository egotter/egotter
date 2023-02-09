class SessionsController < ApplicationController

  skip_before_action :validate_api_authorization!
  skip_before_action :validate_account_suspension!
  skip_before_action :validate_dm_permission!
  skip_before_action :current_user_not_blocker?

  before_action :reject_crawler

  def new
    counter = LoginCounter.new(current_visit.visitor_token)
    if counter.value > 0
      @consecutive_access = true
      Airbag.info 'Consecutive access found', count: counter.value, visitor_token: current_visit.visitor_token
    end
    counter.increment
  rescue => e
  end
end
