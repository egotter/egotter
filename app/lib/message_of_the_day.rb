class MessageOfTheDay
  def initialize(uid)
    @seed = uid + Time.zone.now.strftime('%Y%m%d').to_i
  end

  def to_s
    type = :color
    "#{title(type)}: #{send(type, @seed)}"
  end

  private

  def title(type)
    case type
    when :color
      I18n.t('message_of_the_day.color.title')
    else
      raise "Invalid type value=#{type}"
    end
  end

  def color(seed)
    self.class.colors.sample(random: Random.new(seed))
  rescue => e
    I18n.t('message_of_the_day.color.default')
  end

  class << self
    def colors
      @colors ||= File.read(Rails.root.join('config/lucky_colors.txt')).split("\n")
    end
  end
end
