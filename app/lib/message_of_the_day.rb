require 'forwardable'
require 'singleton'

class MessageOfTheDay
  include Singleton

  COLORS = File.read(Rails.root.join('config/lucky_colors.txt')).split("\n")

  def message(uid)
    seed = uid + Time.zone.now.strftime('%Y%m%d').to_i
    color = COLORS.sample(random: Random.new(seed))
    I18n.t('message_of_the_day.messages', color: color).sample(random: Random.new(seed))
  end

  class << self
    extend Forwardable
    def_delegators :instance, :message
  end
end
