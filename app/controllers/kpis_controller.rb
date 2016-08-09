class KpisController < ApplicationController
  before_action :basic_auth

  def index
  end

  def dau
    return render unless request.xhr?

    result =
      if params[:type].nil?
        {dau: fetch_dau}
      else
        {params[:type] => send("fetch_#{params[:type]}")}
      end
    render json: result, status: 200
  end

  def search_num
    return render unless request.xhr?

    result =
      if params[:type].nil?
        {search_num: fetch_search_num}
      else
        {params[:type] => send("fetch_#{params[:type]}")}
      end
    render json: result, status: 200
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
    return render unless request.xhr?

    result = {twitter_users: fetch_twitter_users_num}
    if request.referer.end_with?(action_name)
      result.update(
        twitter_users_uid: fetch_twitter_users_uid_num,
        friends: fetch_friends_num,
        followers: fetch_followers_num
      )
    end
    render json: result, status: 200
  end

  def rr
    return render unless request.xhr?

    id_type = %w(user_id uid).include?(params[:id_type]) ? params[:id_type] : :session_id
    date_index_max = [params[:date_index_max].to_i, 9].min
    date_start_index = [params[:date_start_index].to_i, 0].max
    date_end_index = [params[:date_end_index].to_i, date_index_max].min
    y_index_range = date_start_index..date_end_index
    yAxis_categories = (date_index_max + 1).times.map { |i| (NOW - i.days) }
    xAxis_categories = (date_index_max + 1).times.to_a
    cells = {}

    yAxis_categories.each.with_index do |day, y|
      next unless y_index_range.include?(y)

      ids = SearchLog.except_crawler.where(created_at: day.all_day).select(id_type).uniq.pluck(id_type)
      xAxis_categories.each do |x|
        if ids.empty?
          cells[[x, y]] = 0
          next
        end
        cells[[x, y]] = SearchLog.except_crawler.where(created_at: (day + x.days).all_day, id_type => ids).count("DISTINCT #{id_type}")
      end
    end

    format = params[:format] == 'percentage' ? 'percentage' : 'number'
    if format == 'percentage'
      tmp = {}
      cells.each do |(x, y), cell|
        value = cells[[0, y]].to_i == 0 ? 0.0 : 100.0 * cell / cells[[0, y]]
        tmp[[x, y]] = value.round(1)
      end
      cells = tmp
    end

    result = {
      title: "RR(#{id_type}, #{format})",
      format: format,
      id_type: id_type,
      date_index_max: date_index_max,
      date_start_index: date_start_index,
      date_end_index: date_end_index,
      xAxis_categories: xAxis_categories.dup,
      yAxis_categories: yAxis_categories.map { |d| d.to_date.strftime('%m/%d') },
      cells: cells.map { |(x, y), cell| [x, y, cell] }
    }
    render json: result, status: 200
  end

  private

  NOW = Time.zone.now
  PAST_2_WEEKS = {start: (NOW - 14.days).beginning_of_day, end: NOW.end_of_day}

  def fetch_dau
    result = SearchLog.find_by_sql([dau_sql, PAST_2_WEEKS])
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

  def fetch_dau_per_action
    result = SearchLog.find_by_sql([dau_per_action_sql, PAST_2_WEEKS])
    result.map { |r| r.action.to_s }.sort.uniq.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(new create show))
      }
    end
  end

  def dau_per_action_sql
    <<-'SQL'.strip_heredoc
      -- dau_per_action
      SELECT
        date(created_at) date,
        action,
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), action
      ORDER BY date(created_at), action;
    SQL
  end

  def fetch_pv_per_action
    result = SearchLog.find_by_sql([pv_per_action_sql, PAST_2_WEEKS])
    result.map { |r| r.action.to_s }.sort.uniq.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(new create show))
      }
    end
  end

  def pv_per_action_sql
    <<-'SQL'.strip_heredoc
      -- pv_per_action
      SELECT
        date(created_at) date,
        action,
        count(*) total
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
    result = SearchLog.find_by_sql([dau_by_new_action_sql, PAST_2_WEEKS])
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

  def fetch_pv_by_new_action
    result = SearchLog.find_by_sql([pv_by_new_action_sql, PAST_2_WEEKS])
    %i(total).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def pv_by_new_action_sql
    <<-'SQL'.strip_heredoc
      SELECT
        date(created_at) date,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'new'
      GROUP BY date(created_at)
      ORDER BY date(created_at);
    SQL
  end

  def fetch_dau_per_device_type
    result = SearchLog.find_by_sql([dau_per_device_type_sql, PAST_2_WEEKS])
    result.map { |r| r.device_type.to_s }.sort.uniq.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
      }
    end
  end

  def dau_per_device_type_sql
    <<-'SQL'.strip_heredoc
      -- dau_per_device_type
      SELECT
        date(created_at) date,
        device_type,
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), device_type
      ORDER BY date(created_at), device_type;
    SQL
  end

  def fetch_pv_per_device_type
    result = SearchLog.find_by_sql([pv_per_device_type_sql, PAST_2_WEEKS])
    result.map { |r| r.device_type.to_s }.sort.uniq.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
      }
    end
  end

  def pv_per_device_type_sql
    <<-'SQL'.strip_heredoc
      -- pv_per_device_type
      SELECT
        date(created_at) date,
        device_type,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), device_type
      ORDER BY date(created_at), device_type;
    SQL
  end

  def fetch_dau_per_referer
    result = SearchLog.find_by_sql([dau_per_referer_sql, PAST_2_WEEKS])
    result.map { |r| r.channel.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(others))
      }
    end
  end

  def dau_per_referer_sql
    <<-'SQL'.strip_heredoc
      -- dau_per_referer
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
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), channel
      ORDER BY date(created_at), channel;
    SQL
  end

  def fetch_pv_per_referer
    result = SearchLog.find_by_sql([pv_per_referer_sql, PAST_2_WEEKS])
    result.map { |r| r.channel.to_s }.uniq.sort.map do |legend|
      {
        name: legend,
        data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
        visible: !legend.in?(%w(others))
      }
    end
  end

  def pv_per_referer_sql
    <<-'SQL'.strip_heredoc
      -- pv_per_referer
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
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at), channel
      ORDER BY date(created_at), channel;
    SQL
  end

  def fetch_search_num
    result = SearchLog.find_by_sql([search_num_sql, PAST_2_WEEKS])
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
    result = SearchLog.find_by_sql([search_num_verification_sql, PAST_2_WEEKS])
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

  def fetch_search_num_per_action
    result = SearchLog.find_by_sql([search_num_per_action_sql, PAST_2_WEEKS])
    %i(top result direct).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
      }
    end
  end

  def search_num_per_action_sql
    <<-'SQL'.strip_heredoc
      -- searh_num_per_action
      SELECT
        date(created_at) date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/?$', session_id, NULL)) top,
        count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/searches', session_id, NULL)) result,
        count(DISTINCT if(referer = '', session_id, NULL)) direct
      FROM background_search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY date(created_at)
    SQL
  end

  def fetch_search_rate_per_action
    result = SearchLog.find_by_sql([search_rate_per_action_sql, PAST_2_WEEKS])
    %i(top result direct).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
      }
    end
  end

  def search_rate_per_action_sql
    <<-'SQL'.strip_heredoc
      -- searh_rate_per_action
      SELECT
        a.date,
        if(a.total = 0, 0, a.top / a.total) top,
        if(a.total = 0, 0, a.result / a.total) result,
        if(a.total = 0, 0, a.direct / a.total) direct
      FROM (
        SELECT
          date(created_at) date,
          count(DISTINCT session_id) total,
          count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/?$', session_id, NULL)) top,
          count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/searches', session_id, NULL)) result,
          count(DISTINCT if(referer = '', session_id, NULL)) direct
        FROM background_search_logs
        WHERE
          created_at BETWEEN :start AND :end
          AND device_type NOT IN ('crawler', 'UNKNOWN')
        GROUP BY date(created_at)
      ) a;
    SQL
  end

  def fetch_search_num_by_google
    result = SearchLog.find_by_sql([search_num_by_google_sql, PAST_2_WEEKS])
    %i(not_search search).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
      }
    end
  end

  def search_num_by_google_sql
    <<-'SQL'.strip_heredoc
      -- search_num_by_google
      SELECT
        a.date,
        count(if(b.session_id IS NULL, 1, NULL)) not_search,
        count(if(b.session_id IS NOT NULL, 1, NULL)) search
      FROM (
        SELECT date(created_at) date, session_id
        FROM search_logs
        WHERE
          created_at BETWEEN :start AND :end
          AND device_type NOT IN ('crawler', 'UNKNOWN')
          AND action = 'new'
          AND referer regexp '^https?://(www\.)?google(\.com|\.co\.jp)'
      ) a LEFT OUTER JOIN (
        SELECT date(created_at) date, session_id
        FROM background_search_logs
        WHERE
          created_at BETWEEN :start AND :end
          AND device_type NOT IN ('crawler', 'UNKNOWN')
          AND referer regexp '^http://(www\.)?egotter\.com/?$'
      ) b ON (a.date = b.date AND a.session_id = b.session_id)
      GROUP BY a.date
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
    result = SearchLog.find_by_sql([sql, PAST_2_WEEKS])

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
    result = SearchLog.find_by_sql([sql, PAST_2_WEEKS])

    %i(NewUser ReturningUser).map do |legend|
      {
        name: legend,
        data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
      }
    end
  end

  def fetch_twitter_users_num
    result = TwitterUser.find_by_sql([twitter_users_num_sql, PAST_2_WEEKS])
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
    result = TwitterUser.find_by_sql([twitter_users_uid_num_sql, PAST_2_WEEKS])
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
    result = Friend.find_by_sql([friends_num_sql, PAST_2_WEEKS])
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
    result = Follower.find_by_sql([followers_num_sql, PAST_2_WEEKS])
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
