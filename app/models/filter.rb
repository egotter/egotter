class Filter
  VALUES = [
      [I18n.t('filter.inactive'), 'inactive'],
  ]

  def initialize(value)
    @value = VALUES.map {|f| f[1]}.include?(value) ? value : self.class.default_filter
  end

  def apply!(users)
    case @value
    when VALUES[0][1] then users.select!(&:inactive?)
    end
  end

  def default_filter?
    @value == self.class.default_filter
  end

  def self.default_filter
    nil
  end
end
