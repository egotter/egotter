class DebugController < ApplicationController
  before_action :basic_auth, only: %i(index)

  def index
    @debug_info = Hashie::Mash.new(JSON.parse(redis.get(Redis.debug_info_key) || '{}'))
    @last_1hour = 1.hour.ago..Time.now
    @last_1day = 1.day.ago..Time.now
    @last_1week = (1.week.ago + 1.day)..Time.now
    @dau = dau
    render layout: false
  end

  private

  def dau
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at) date,
        count(DISTINCT session_id) count
      FROM search_logs
      WHERE device_type != 'crawler' AND created_at >= :date
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    {
      name: 'dau',
      data: result.map{|r| [ActiveSupport::TimeZone['UTC'].parse(r.date.to_s).to_i * 1000, r.count] }
    }
  end
end
