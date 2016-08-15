module KpiAdmin
  module Kpis
    module DailyHelper
      def fetch_dau
        result = SearchLog.find_by_sql([dau_sql, past_30_days])
        %i(total guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def dau_sql
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
      GROUP BY date(created_at)
      ORDER BY date(created_at);
        SQL
      end

      def fetch_dau_per_action
        result = SearchLog.find_by_sql([dau_per_action_sql, past_30_days])
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

      def fetch_daily_pv_per_action
        result = SearchLog.find_by_sql([daily_pv_per_action_sql, past_30_days])
        result.map { |r| r.action.to_s }.sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(new create show))
          }
        end
      end

      def daily_pv_per_action_sql
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
        result = SearchLog.find_by_sql([dau_by_new_action_sql, past_30_days])
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

      def fetch_daily_pv_by_new_action
        result = SearchLog.find_by_sql([daily_pv_by_new_action_sql, past_30_days])
        %i(total).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def daily_pv_by_new_action_sql
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
        result = SearchLog.find_by_sql([dau_per_device_type_sql, past_30_days])
        result.map { |r| r.device_type.to_s }.sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
          }
        end
      end

      def dau_per_device_type_sql
        <<-'SQL'.strip_heredoc
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

      def fetch_daily_pv_per_device_type
        result = SearchLog.find_by_sql([daily_pv_per_device_type_sql, past_30_days])
        result.map { |r| r.device_type.to_s }.sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
          }
        end
      end

      def daily_pv_per_device_type_sql
        <<-'SQL'.strip_heredoc
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
        result = SearchLog.find_by_sql([dau_per_referer_sql, past_30_days])
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

      def fetch_daily_pv_per_referer
        result = SearchLog.find_by_sql([daily_pv_per_referer_sql, past_30_days])
        result.map { |r| r.channel.to_s }.uniq.sort.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(others))
          }
        end
      end

      def daily_pv_per_referer_sql
        <<-'SQL'.strip_heredoc
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

      def fetch_daily_search_num
        result = SearchLog.find_by_sql([daily_search_num_sql, past_30_days])
        %i(guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def daily_search_num_sql
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

      def fetch_daily_search_num_verification
        result = SearchLog.find_by_sql([daily_search_num_verification_sql, past_30_days])
        %i(guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def daily_search_num_verification_sql
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

      def fetch_daily_search_num_per_action
        result = SearchLog.find_by_sql([daily_search_num_per_action_sql, past_30_days])
        %i(top result direct).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
          }
        end
      end

      def daily_search_num_per_action_sql
        <<-'SQL'.strip_heredoc
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

      def fetch_daily_search_rate_per_action
        result = SearchLog.find_by_sql([daily_search_rate_per_action_sql, past_30_days])
        %i(top result direct).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
          }
        end
      end

      def daily_search_rate_per_action_sql
        <<-'SQL'.strip_heredoc
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

      def fetch_daily_search_num_by_google
        result = SearchLog.find_by_sql([daily_search_num_by_google_sql, past_30_days])
        %i(not_search search).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
          }
        end
      end

      def daily_search_num_by_google_sql
        <<-'SQL'.strip_heredoc
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
    end
  end
end
