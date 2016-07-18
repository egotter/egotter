class DebugController < ApplicationController
  before_action :basic_auth, only: %i(index)

  def index
    @debug_info = Hashie::Mash.new(JSON.parse(redis.get(Redis.debug_info_key) || '{}'))
    @last_1hour = 1.hour.ago..Time.now
    @last_1day = 1.day.ago..Time.now
    @last_1week = (1.week.ago + 1.day)..Time.now
    render layout: false
  end
end
