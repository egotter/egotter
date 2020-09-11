require 'active_support/concern'

module SearchCountLimitationConcern
  extend ActiveSupport::Concern

  included do
    before_action do
      @search_count_limitation = SearchCountLimitation.new(user: current_user, session_id: egotter_visit_id)
    end
  end
end
