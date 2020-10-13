module SearchCountLimitationHelper
  def search_count_reset_in_words(seconds)
    if seconds > 1.hour
      t('datetime.distance_in_words.about_x_hours', count: (seconds / 3600).to_i)
    elsif seconds > 10.minutes
      t('datetime.distance_in_words.x_minutes', count: (seconds / 60).to_i)
    else
      t('datetime.distance_in_words.x_seconds', count: seconds.to_i)
    end
  end

  def search_modal_icon_style(mobile = true)
    if mobile
      @search_count_limitation.count_remaining? ? 'text-white' : 'text-warning'
    else
      @search_count_limitation.count_remaining? ? 'btn-outline-primary' : 'btn-outline-warning'
    end
  end
end
