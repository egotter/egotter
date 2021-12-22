class Users::SessionsController < Devise::SessionsController
  include SearchHistoriesConcern

  skip_before_action :current_user_not_blocker?

  def destroy
    update_search_histories_when_signing_out { super }
  end
end
