require 'active_support/concern'

module SearchRequestCreation
  extend ActiveSupport::Concern

  included do
    before_action(only: :show) { head :forbidden if twitter_dm_crawler? }

    before_action(only: :show) { validate_screen_name! }
    before_action(only: :show) { find_or_create_search_request }
    before_action(only: :show) { twitter_user_persisted?(@twitter_user.uid) }
    before_action(only: :show) { twitter_db_user_persisted?(@twitter_user.uid) } # Not redirected
    before_action(only: :show) { @twitter_user = TwitterUser.with_delay.latest_by(uid: @twitter_user.uid) }
  end

  def find_or_create_search_request(screen_name = nil)
    screen_name ||= params[:screen_name]

    if user_signed_in? && current_user.screen_name == screen_name
      @twitter_user = TwitterUser.new(uid: current_user.uid, screen_name: current_user.screen_name)
      return
    end

    # TODO Save visitor_token
    request = SearchRequest.request_for(current_user&.id, screen_name: screen_name)

    if request
      if request.ok?
        @twitter_user = TwitterUser.new(uid: request.uid, screen_name: request.screen_name)
      else
        session[:screen_name] = request.screen_name
        redirect_to redirect_path_for_search_request(request)
      end
    else
      # TODO Prevent from creating duplicate records
      request = SearchRequest.create!(
          user_id: current_user&.id,
          uid: nil,
          screen_name: screen_name,
          properties: {remaining_count: @search_count_limitation.remaining_count, search_histories: current_search_histories.map(&:uid)}
      )
      CreateSearchRequestWorker.perform_async(request.id)

      # TODO Prevent from redirecting many times
      @screen_name = request.screen_name
      @user = TwitterDB::User.find_by(screen_name: request.screen_name)
      self.sidebar_disabled = true
      self.footer_disabled = true
      render template: 'searches/create'
    end
  end
end
