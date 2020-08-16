require 'active_support/concern'

module Concerns::SearchCountSummary
  extend ActiveSupport::Concern

  def search_count_summary(user)
    limitation = SearchCountLimitation.new(user: user, session_id: nil)
    {
        user_id: user.id,
        search_count: {
            max: limitation.max_count,
            remaining: limitation.remaining_count,
            current: limitation.current_count,
            sharing_bonus: limitation.current_sharing_bonus,
            sharing_count: user.sharing_count,
        },
    }
  end
end
