class Filter
  VALUES = [
      [I18n.t('filter.active'), 'active'],
      [I18n.t('filter.inactive'), 'inactive'],
      [I18n.t('filter.protected'), 'protected'],
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
        end
      end
    end
  end

  def default_filter?
    @values.blank?
  end
end
