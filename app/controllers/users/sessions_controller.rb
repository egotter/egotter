class Users::SessionsController < Devise::SessionsController
  include Concerns::SearchHistoriesConcern

  def destroy
    update_search_histories_when_signing_out { super }
  end
end
