require 'active_support/concern'

module Concerns::SearchCountSummary
  extend ActiveSupport::Concern

  def search_count_summary(user)
    {
        user_id: user.id,
        search_count: {
            max: SearchCountLimitation.max_count(user),
            remaining: SearchCountLimitation.remaining_count(user: user),
            current: SearchCountLimitation.current_count(user: user),
            sharing_bonus: SearchCountLimitation.current_sharing_bonus(user),
            sharing_count: user.sharing_count,
        },
    }
  end
end
