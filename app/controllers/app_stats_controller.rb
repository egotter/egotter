class AppStatsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @chart_data = generate_chart_data
  end

  private

  def generate_chart_data
    time = Time.zone.now.in_time_zone('Asia/Tokyo') - 1.day
    previous_data = User.select('gd_hour(created_at, "UTC") time, count(*) cnt').where(created_at: time.beginning_of_day..time.end_of_day).group('time')

    time = Time.zone.now.in_time_zone('Asia/Tokyo')
    current_data = User.select('gd_hour(created_at, "UTC") time, count(*) cnt').where(created_at: time.beginning_of_day..time.end_of_day).group('time')

    [previous_data.map(&:cnt), current_data.map(&:cnt)]
  rescue => e
    [[], []]
  end
end
