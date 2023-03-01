require 'active_support/concern'

module SearchCountLimitationConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_search_count_limitation
  end

  def set_search_count_limitation
    @search_count_limitation = SearchCountLimitation.new(user: current_user, session_id: egotter_visit_id)
  end
end
