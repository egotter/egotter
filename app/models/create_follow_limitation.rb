class CreateFollowLimitation

  ANONYMOUS = Rails.configuration.x.constants['create_follow_limitation']['anonymous']
  BASIC_PLAN = Rails.configuration.x.constants['create_follow_limitation']['basic_plan']

  CREATE_FOLLOW_PERIOD = 1.day.to_i

  class << self
    def max_count(user)
      if user&.has_valid_subscription?
        followers_count = TwitterUser.latest_by(uid: user.uid)&.followers_count
        followers_count = TwitterDB::User.find_by(uid: user.uid)&.followers_count unless followers_count
        followers_count = user.api_client.user[:followers_count] unless followers_count

        case followers_count
          when 0..99      then 20
          when 100..499   then 30
          when 500..999   then 40
          when 1000..1999 then 50
          when 2000..2999 then 70
          else BASIC_PLAN
        end
      else
        ANONYMOUS
      end
    end

    def remaining_count(user)
      [0, max_count(user) - current_count(user)].max
    end

    def follow_requests(user)
      user.follow_requests.
          where.not(uid: User::EGOTTER_UID).
          where(created_at: CREATE_FOLLOW_PERIOD.seconds.ago..Time.zone.now)
    end

    def current_count(user)
      follow_requests(user).size
    end

    def count_reset_in(user)
      record = follow_requests(user).last
      record ? [0, (record.created_at + CREATE_FOLLOW_PERIOD.seconds - Time.zone.now).to_i].max : 0
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
