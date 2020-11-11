class Filter
  VALUES = [
      [I18n.t('filter.active'), 'active'],
      [I18n.t('filter.inactive_2weeks'), 'inactive_2weeks'],
      [I18n.t('filter.inactive_1month'), 'inactive_1month'],
      [I18n.t('filter.inactive_3months'), 'inactive_3months'],
      [I18n.t('filter.inactive_6months'), 'inactive_6months'],
      [I18n.t('filter.inactive_1year'), 'inactive_1year'],
      [I18n.t('filter.protected'), 'protected'],
      [I18n.t('filter.verified'), 'verified'],
      [I18n.t('filter.friends_>_followers'), 'friends_>_followers'],
      [I18n.t('filter.followers_>_friends'), 'followers_>_friends'],
      [I18n.t('filter.has_instagram'), 'has_instagram'],
  ]

  def initialize(value)
    valid_values = VALUES.map { |f| f[1] }
    @values = value.to_s.split(',').select { |v| valid_values.include?(v) }
  end

  # users: [TwitterDB::User, TwitterDB::User, ...]
  def apply!(users)
    if @values.any?
      @values.each do |value|
        case value
        when VALUES[0][1] then users.select! { |u| TwitterUserDecorator.new(u).active? }
        when VALUES[1][1] then users.select! { |u| TwitterUserDecorator.new(u).inactive_2weeks? }
        when VALUES[2][1] then users.select! { |u| TwitterUserDecorator.new(u).inactive_1month? }
        when VALUES[3][1] then users.select! { |u| TwitterUserDecorator.new(u).inactive_3months? }
        when VALUES[4][1] then users.select! { |u| TwitterUserDecorator.new(u).inactive_6months? }
        when VALUES[5][1] then users.select! { |u| TwitterUserDecorator.new(u).inactive_1year? }
        when VALUES[6][1] then users.select!(&:protected?)
        when VALUES[7][1] then users.select!(&:verified?)
        when VALUES[8][1] then users.select! { |user| user.friends_count > user.followers_count }
        when VALUES[9][1] then users.select! { |user| user.followers_count > user.friends_count }
        when VALUES[10][1] then users.select! { |u| TwitterUserDecorator.new(u).has_instagram? }
        else raise "Invalid filter value=#{value}"
        end
      end
    end
  end

  def default_filter?
    @values.blank?
  end
end
