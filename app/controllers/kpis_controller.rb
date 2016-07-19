class KpisController < ApplicationController
  before_action :basic_auth, only: %i(index)

  def index
    @dau = dau
    @dau_by_action = dau_by_action
    @search_num = search_num
    @search_num_verification = search_num_verification
    @new_user = new_user
    @sign_in = sign_in
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
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def dau_by_action
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at) date,
        action,
        count(*)         total
      FROM search_logs
      WHERE device_type != 'crawler' AND action != 'waiting' AND created_at >= :date
      GROUP BY date(created_at), action
      ORDER BY date(created_at), action;
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    result.map { |r| r.action.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
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

    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def search_num_verification
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at)                  date,
        count(*)                          total,
        count(if(user_id = -1, 1, NULL))  guest,
        count(if(user_id != -1, 1, NULL)) login
      FROM background_search_logs
      WHERE created_at >= :date
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def new_user
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total
      FROM users
      WHERE created_at >= :date
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    %i(total).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def sign_in
    sql = <<-'EOS'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total,
        count(if(context = 'create', 1, NULL)) 'NewUser',
        count(if(context = 'update', 1, NULL)) 'ExistingUser'
      FROM sign_in_logs
      WHERE created_at >= :date
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    EOS
    result = SearchLog.find_by_sql([sql, {date: (Time.zone.now - 14.days).to_date.to_s}])

    %i(NewUser ExistingUser).map do |legend|
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
