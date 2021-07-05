class AppStatsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @chart_data = generate_chart_data
  end

  private

  def generate_chart_data
    time = Time.zone.now.in_time_zone('Asia/Tokyo') - 1.day
    previous_data = User.select('gd_hour(created_at, "UTC") time, count(*) cnt').where(created_at: time.beginning_of_day..time.end_of_day).group('time').map(&:cnt)
    previous_data = previous_data.map.with_index { |_, i| previous_data.take(i + 1).sum }

    time = Time.zone.now.in_time_zone('Asia/Tokyo')
    current_data = User.select('gd_hour(created_at, "UTC") time, count(*) cnt').where(created_at: time.beginning_of_day..time.end_of_day).group('time').map(&:cnt)
    current_data = current_data.map.with_index { |_, i| current_data.take(i + 1).sum }

    [previous_data, current_data]
  rescue => e
    [[], []]
  end
end
