class Filter
  VALUES = [
      [I18n.t('filter.active'), 'active'],
      [I18n.t('filter.inactive'), 'inactive'],
      [I18n.t('filter.protected'), 'protected'],
      [I18n.t('filter.verified'), 'verified'],
      [I18n.t('filter.friends_>_followers'), 'friends_>_followers'],
      [I18n.t('filter.followers_>_friends'), 'followers_>_friends'],
  ]

  def initialize(value)
    valid_values = VALUES.map { |f| f[1] }
    @values = value.to_s.split(',').select { |v| valid_values.include?(v) }
  end

  def apply!(users)
    if @values.any?
      @values.each do |value|
        case value
        when VALUES[0][1] then users.select!(&:active?)
        when VALUES[1][1] then users.select!(&:inactive?)
        when VALUES[2][1] then users.select!(&:protected?)
        when VALUES[3][1] then users.select!(&:verified?)
        when VALUES[4][1] then users.select! { |user| user.friends_count > user.followers_count }
        when VALUES[5][1] then users.select! { |user| user.followers_count > user.friends_count }
        else raise "Invalid filter value=#{value}"
        end
      end
    end
  end

  def default_filter?
    @values.blank?
  end
end
