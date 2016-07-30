class DebugController < ApplicationController
  before_action :basic_auth

  def index
    @debug_info = Hashie::Mash.new(JSON.parse(redis.get(Redis.debug_info_key) || '{}'))
    @last_1hour = 1.hour.ago..Time.zone.now
    @last_1day = 1.day.ago..Time.zone.now
    @last_1week = (1.week.ago + 1.day)..Time.zone.now
    render layout: false
  end
end
