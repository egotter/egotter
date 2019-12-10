class CreateUnfollowLimitation

  ANONYMOUS = Rails.configuration.x.constants['create_unfollow_limitation']['anonymous']
  BASIC_PLAN = Rails.configuration.x.constants['create_unfollow_limitation']['basic_plan']

  CREATE_UNFOLLOW_PERIOD = 1.day.to_i

  class << self
    def max_count(user)
      user&.has_valid_subscription? ? BASIC_PLAN : ANONYMOUS
    end

    def remaining_count(user)
      [0, max_count(user) - current_count(user)].max
    end

    def unfollow_requests(user)
      user.unfollow_requests.
          where(created_at: CREATE_UNFOLLOW_PERIOD.seconds.ago..Time.zone.now)
    end

    def current_count(user)
      unfollow_requests(user).size
    end

    def count_reset_in(user)
      record = unfollow_requests(user).last
      record ? [0, (record.created_at + 1.day - Time.zone.now).to_i].max : 0
    end

    module DateHelper
      extend ActionView::Helpers::DateHelper
    end

    def count_reset_in_words(user)
      seconds = count_reset_in(user)

      if seconds > 1.hour
        I18n.t('datetime.distance_in_words.about_x_hours', count: (seconds / 3600).to_i)
      elsif seconds > 10.minutes
        I18n.t('datetime.distance_in_words.x_minutes', count: (seconds / 60).to_i)
      else
        I18n.t('datetime.distance_in_words.x_seconds', count: seconds.to_i)
      end
    end
  end
end
