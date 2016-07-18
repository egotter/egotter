class KpisController < ApplicationController
  before_action :basic_auth, only: %i(index)

  def index
    @dau = dau
    @search_num = search_num
    @new_user = new_user
  end

  private

  def dau
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at) date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(user_id = -1, session_id, NULL)) guest,
        count(DISTINCT if(user_id != -1, session_id, NULL)) login
      FROM search_logs
      WHERE device_type != 'crawler' AND created_at >= :date
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    %i(total guest login).map do |legend|
      {
        name: legend,
        data: result.map{|r| [ActiveSupport::TimeZone['UTC'].parse(r.date.to_s).to_i * 1000, r.send(legend)] }
      }
    end
  end

  def search_num
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at)                                    date,
        count(*)                                            total,
        count(if(user_id = -1, 1, NULL))                    guest,
        count(if(user_id != -1, 1, NULL))                   login
      FROM search_logs
      WHERE device_type != 'crawler' AND created_at >= :date AND action = 'create'
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    %i(total guest login).map do |legend|
      {
        name: legend,
        data: result.map{|r| [ActiveSupport::TimeZone['UTC'].parse(r.date.to_s).to_i * 1000, r.send(legend)] }
      }
    end
  end

  def new_user
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) count
      FROM users
      WHERE created_at >= :date
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    %i(total).map do |legend|
      {
        name: legend,
        data: result.map{|r| [ActiveSupport::TimeZone['UTC'].parse(r.date.to_s).to_i * 1000, r.send(legend)] }
      }
    end
  end
end
