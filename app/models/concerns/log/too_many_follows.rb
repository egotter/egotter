require 'active_support/concern'

module Concerns::Log::TooManyFollows
  extend ActiveSupport::Concern

  class_methods do
    def global_last_too_many_follows_time
      order(created_at: :desc).
          where(status: false).
          find_by('error_class like ?', "%#{sanitize_sql_like('TooManyFollows')}")
    end

    def user_last_too_many_follows_time(user_id)
      order(created_at: :desc).
          where(status: false).
          where(user_id: user_id).
          find_by('error_class like ?', "%#{sanitize_sql_like('TooManyFollows')}")
    end
  end

  included do
  end
end
