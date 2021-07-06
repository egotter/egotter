class AppStatsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @chart_data = {
        day: generate_chart_data('day'),
        week: generate_chart_data('week'),
    }
  end

  private

  def generate_chart_data(period)
    time = Time.zone.now.in_time_zone('Asia/Tokyo').beginning_of_day

    if period == 'day'
      x_times = 24.times.map { |n| time + n.hours }
      categories = x_times.map.with_index do |t, i|
        t = t.change(min: 59) if i == x_times.size - 1
        t.strftime('%H:%M')
      end
      series = [time_to_points('day', time - 24.hours), time_to_points('day', time)]
    elsif period == 'week'
      x_times = 7.times.map { |n| time + n.days }
      categories = x_times.map.with_index do |t, i|
        t = t.change(hour: 23, min: 59) if i == x_times.size - 1
        t.strftime('%m/%d %H:%M')
      end
      series = [time_to_points('week', time - 7.days), time_to_points('week', time)]
    else
      # TODO
    end

    {categories: categories, series: series}
  rescue => e
    logger.warn "#{__method__}: #{e.inspect}"
    logger.info e.backtrace.join("\n")
    {error: e.inspect}
  end

  def time_to_points(period, time)

    if period == 'day'
      times = 24.times.map do |n|
        start_time = time + n.hours
        end_time = start_time + 1.hour - 1.second
        [start_time, end_time]
      end
    elsif period == 'week'
      times = 7.times.map do |n|
        start_time = time + n.days
        end_time = start_time + 1.day - 1.second
        [start_time, end_time]
      end
    else
      # TODO
    end

    now = Time.zone.now
    values = times.map do |start_time, end_time|
      if now < start_time
        nil
      else
        User.where(created_at: start_time..end_time).size
      end
    end
    values.map.with_index { |v, i| v ? values.take(i + 1).sum : nil }
  end
end
