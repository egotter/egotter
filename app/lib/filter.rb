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
      [I18n.t('filter.investor'), 'investor'],
      [I18n.t('filter.engineer'), 'engineer'],
      [I18n.t('filter.designer'), 'designer'],
      [I18n.t('filter.bikini_model'), 'bikini_model'],
      [I18n.t('filter.fashion_model'), 'fashion_model'],
      [I18n.t('filter.pop_idol'), 'pop_idol'],
      [I18n.t('filter.too_emotional'), 'too_emotional'],
      [I18n.t('filter.has_instagram'), 'has_instagram'],
      [I18n.t('filter.has_tiktok'), 'has_tiktok'],
      [I18n.t('filter.has_secret_account'), 'has_secret_account'],
      [I18n.t('filter.adult_account'), 'adult_account'],
  ]

  def initialize(value)
    valid_values = VALUES.map { |f| f[1] }
    @values = value.to_s.split(',').select { |v| valid_values.include?(v) }
  end

  # users: [TwitterDB::User, TwitterDB::User, ...]
  def apply!(users)
    if @values.any?
      tmp = users.map { |u| TwitterUserDecorator.new(u) }

      @values.each do |value|
        case value
        when VALUES[0][1] then tmp.select!(&:active?)
        when VALUES[1][1] then tmp.select!(&:inactive_2weeks?)
        when VALUES[2][1] then tmp.select!(&:inactive_1month?)
        when VALUES[3][1] then tmp.select!(&:inactive_3months?)
        when VALUES[4][1] then tmp.select!(&:inactive_6months?)
        when VALUES[5][1] then tmp.select!(&:inactive_1year?)
        when VALUES[6][1] then tmp.select!(&:protected_account?)
        when VALUES[7][1] then tmp.select!(&:verified_account?)
        when VALUES[8][1] then tmp.select!(&:has_more_friends?)
        when VALUES[9][1] then tmp.select!(&:has_more_followers?)
        when VALUES[10][1] then tmp.select!(&:investor?)
        when VALUES[11][1] then tmp.select!(&:engineer?)
        when VALUES[12][1] then tmp.select!(&:designer?)
        when VALUES[13][1] then tmp.select!(&:bikini_model?)
        when VALUES[14][1] then tmp.select!(&:fashion_model?)
        when VALUES[15][1] then tmp.select!(&:pop_idol?)
        when VALUES[16][1] then tmp.select!(&:too_emotional?)
        when VALUES[17][1] then tmp.select!(&:has_instagram?)
        when VALUES[18][1] then tmp.select!(&:has_tiktok?)
        when VALUES[19][1] then tmp.select!(&:has_secret_account?)
        when VALUES[20][1] then tmp.select!(&:adult_account?)
        else raise "Invalid filter value=#{value}"
        end
      end

      uids_map = tmp.index_by(&:uid)
      users.select! { |u| uids_map[u.uid] }
    end
  end

  def default_filter?
    @values.blank?
  end
end
