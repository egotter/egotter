class KpisController < ApplicationController
  before_action :basic_auth

  def index
  end

  def dau
    if request.xhr?
      result = {dau: fetch_dau}
      if request.referer.end_with?(action_name)
        result.update(
          dau_by_action: fetch_dau_by_action,
          dau_by_new_action: fetch_dau_by_new_action,
          dau_by_device_type: fetch_dau_by_device_type,
          dau_by_referer: fetch_dau_by_referer
        )
      end
      return render json: result, status: 200
    end
  end

  def search_num
    if request.xhr?
      result = {search_num: fetch_search_num}
      if request.referer.end_with?(action_name)
        result.update(
          search_num_verification: fetch_search_num_verification
        )
      end
      return render json: result, status: 200
    end
  end

  def new_user
    result = {
      new_user: fetch_new_user
    }
    render json: result, status: 200
  end

  def sign_in
    result = {
      sign_in: fetch_sign_in
    }
    render json: result, status: 200
  end

  def table
    if request.xhr?
      result = {twitter_users: fetch_twitter_users_num}
      if request.referer.end_with?(action_name)
        result.update(
          twitter_users_uid: fetch_twitter_users_uid_num,
          friends: fetch_friends_num,
          followers: fetch_followers_num
        )
      end
      return render json: result, status: 200
    end
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

  def fetch_dau
    result = SearchLog.find_by_sql([dau_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(total guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def dau_sql
    <<-'SQL'.strip_heredoc
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
  end

  def fetch_dau_by_action
    result = SearchLog.find_by_sql([dau_by_action_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    result.map { |r| r.action.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(new create show))
      }
    end
  end

  def dau_by_action_sql
    <<-'SQL'.strip_heredoc
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
  end

  def fetch_dau_by_new_action
    result = SearchLog.find_by_sql([dau_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(total guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def dau_by_new_action_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at) date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(user_id = -1, session_id, NULL)) guest,
        count(DISTINCT if(user_id != -1, session_id, NULL)) login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'new'
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def fetch_dau_by_device_type
    result = SearchLog.find_by_sql([dau_by_device_type_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    result.map { |r| r.device_type.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
      }
    end
  end

  def dau_by_device_type_sql
    <<-'SQL'.strip_heredoc
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
  end

  def fetch_dau_by_referer
    result = SearchLog.find_by_sql([dau_by_referer_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    result.map { |r| r.channel.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(egotter others))
      }
    end
  end

  def dau_by_referer_sql
    <<-'SQL'.strip_heredoc
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
  end

  def fetch_search_num
    result = SearchLog.find_by_sql([search_num_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def search_num_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at)                  date,
        count(*)                          total,
        count(if(user_id = -1, 1, NULL))  guest,
        count(if(user_id != -1, 1, NULL)) login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'create'
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def fetch_search_num_verification
    result = SearchLog.find_by_sql([search_num_verification_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def search_num_verification_sql
    <<-'SQL'.strip_heredoc
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
  end

  def fetch_new_user
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

  def fetch_sign_in
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

  def fetch_twitter_users_num
    result = TwitterUser.find_by_sql([twitter_users_num_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(guest login).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def twitter_users_num_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total,
        count(if(user_id = -1, -1, NULL)) guest,
        count(if(user_id != -1, user_id, NULL)) login
      FROM twitter_users
      WHERE
        created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def fetch_twitter_users_uid_num
    result = TwitterUser.find_by_sql([twitter_users_uid_num_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(total unique_uid).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def twitter_users_uid_num_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total,
        count(DISTINCT uid) unique_uid
      FROM twitter_users
      WHERE
        created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def fetch_friends_num
    result = Friend.find_by_sql([friends_num_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(total).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def friends_num_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total
      FROM friends
      WHERE
        created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def fetch_followers_num
    result = Follower.find_by_sql([followers_num_sql, {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}])
    %i(total).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def followers_num_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total
      FROM followers
      WHERE
        created_at BETWEEN :start AND :end
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def to_msec_unixtime(date)
    ActiveSupport::TimeZone['UTC'].parse(date.to_s).to_i * 1000
  end
end
