class AppStatsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @chart_data = generate_chart_data
  end

  private

  def generate_chart_data
    time = Time.zone.now.in_time_zone('Asia/Tokyo').beginning_of_day
    x_times = 24.times.map { |n| time + n.hours }
    x_labels = x_times.map.with_index do |t, i|
      t = t.change(min: 59) if i == x_times.size - 1
      t.strftime('%H:%M')
    end

    {
        categories: x_labels,
        series: [time_to_points(time - 24.hours), time_to_points(time)]
    }
  rescue => e
    logger.warn "#{__method__}: #{e.inspect}"
    logger.info e.backtrace.join("\n")
    {error: e.inspect}
  end

  def time_to_points(time)
    now = Time.zone.now
    values = 24.times.map do |n|
      start_time = time + n.hours
      end_time = start_time + 1.hour - 1.second
      if now < start_time
        nil
      else
        User.where(created_at: start_time..end_time).size
      end
    end
    values.map.with_index { |v, i| v ? values.take(i + 1).sum : nil }
  end
end
