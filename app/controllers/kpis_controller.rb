class KpisController < ApplicationController
  before_action :basic_auth, only: %i(index rr)

  def index
    @dau = dau
    @dau_by_action = dau_by_action
    @dau_by_device_type = dau_by_device_type
    @dau_by_referer = dau_by_referer
    @search_num = search_num
    @search_num_verification = search_num_verification
    @new_user = new_user
    @sign_in = sign_in
  end

  def rr
    yAxis_categories = 7.times.map { |i| (NOW - i.days) }
    xAxis_categories = (1..9)
    cells = []
    yAxis_categories.each.with_index do |day, y|
      session_ids = SearchLog.except_crawler.where(created_at: day.all_day).pluck(:session_id).uniq
      cells << [0, y, session_ids.size]
      xAxis_categories.each do |x|
        cells << [x, y, SearchLog.except_crawler.where(created_at: (day + x.days).all_day).where(session_id: session_ids).uniq.size]
      end
    end

    @rr = cells
    @yAxis_categories = yAxis_categories.map{|d| d.to_date.strftime('%m/%d') }
    @xAxis_categories = xAxis_categories.to_a << 10
  end

  private

  NOW = Time.zone.now

  def dau
    sql = <<-'SQL'.strip_heredoc
      -- dau
      SELECT
        date(created_at) date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(user_id = -1, session_id, NULL)) guest,
        count(DISTINCT if(user_id != -1, session_id, NULL)) login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    %i(total guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def dau_by_action
    sql = <<-'SQL'.strip_heredoc
      -- dau_by_action
      SELECT
        date(created_at) date,
        action,
        count(*)         total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action != 'waiting'
      GROUP BY date(created_at), action
      ORDER BY date(created_at), action;
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    result.map { |r| r.action.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(new create show))
      }
    end
  end

  def dau_by_device_type
    sql = <<-'SQL'.strip_heredoc
      -- dau_by_device_type
      SELECT
        date(created_at) date,
        device_type,
        count(*)         total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), device_type
      ORDER BY date(created_at), device_type;
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    result.map { |r| r.device_type.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
      }
    end
  end

  def dau_by_referer
    sql = <<-'SQL'.strip_heredoc
      -- dau_by_referer
      SELECT
        date(created_at) date,
        case
          when referer regexp '^http://(www\.)?egotter\.com' then 'egotter'
          when referer regexp '^http://(www\.)?google\.com' then 'google.com'
          when referer regexp '^http://(www\.)?google\.co\.jp' then 'google.co.jp'
          when referer regexp '^http://(www\.)?google\.co\.in' then 'google.co.in'
          when referer regexp '^http://search\.yahoo\.co\.jp' then 'search.yahoo.co.jp'
          when referer regexp '^http://matome\.naver\.jp/(m/)?odai/2136610523178627801$' then 'matome.naver.jp'
          when referer regexp '^http://((m|detail)\.)chiebukuro\.yahoo\.co\.jp' then 'chiebukuro.yahoo.co.jp'
          else 'others'
        end channel,
        count(*)         total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), channel
      ORDER BY date(created_at), channel;
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    result.map { |r| r.channel.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(egotter others))
      }
    end
  end

  def search_num
    sql = <<-'SQL'.strip_heredoc
      -- search_num
      SELECT
        date(created_at)                                    date,
        count(*)                                            total,
        count(if(user_id = -1, 1, NULL))                    guest,
        count(if(user_id != -1, 1, NULL))                   login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'create'
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def search_num_verification
    sql = <<-'SQL'.strip_heredoc
      -- search_num_verification
      SELECT
        date(created_at)                  date,
        count(*)                          total,
        count(if(user_id = -1, 1, NULL))  guest,
        count(if(user_id != -1, 1, NULL)) login
      FROM background_search_logs
      WHERE created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def new_user
    sql = <<-'SQL'.strip_heredoc
      -- new_user
      SELECT
        date(created_at) date,
        count(*) total
      FROM users
      WHERE created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    %i(total).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def sign_in
    sql = <<-'SQL'.strip_heredoc
      -- sign_in
      SELECT
        date(created_at) date,
        count(*) total,
        count(if(context = 'create', 1, NULL)) 'NewUser',
        count(if(context = 'update', 1, NULL)) 'ReturningUser'
      FROM sign_in_logs
      WHERE created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
    result = SearchLog.find_by_sql([sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])

    %i(NewUser ReturningUser).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def to_msec_unixtime(date)
    ActiveSupport::TimeZone['UTC'].parse(date.to_s).to_i * 1000
  end
end
