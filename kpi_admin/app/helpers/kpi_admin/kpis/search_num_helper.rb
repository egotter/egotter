module KpiAdmin
  module Kpis
    module SearchNumHelper
      def fetch_search_num
        result = exec_sql(SearchLog, search_num_sql)
        %i(guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] },
          }
        end
      end

      def search_num_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(*) total,
        count(if(user_id = -1, 1, NULL)) guest,
        count(if(user_id != -1, 1, NULL)) login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'create';
        SQL
      end

      def fetch_search_num_verification
        result = exec_sql(BackgroundSearchLog, search_num_verification_sql)
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
        :label date,
        count(*) total,
        count(if(user_id = -1, 1, NULL)) guest,
        count(if(user_id != -1, 1, NULL)) login
      FROM background_search_logs
      WHERE created_at BETWEEN :start AND :end;
        SQL
      end

      def fetch_search_num_per_action
        result = exec_sql(BackgroundSearchLog, search_num_per_action_sql)
        %i(top result direct).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
          }
        end
      end

      def search_num_per_action_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/?$', session_id, NULL)) top,
        count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/searches', session_id, NULL)) result,
        count(DISTINCT if(referer = '', session_id, NULL)) direct
      FROM background_search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN');
        SQL
      end

      def fetch_search_rate_per_action
        result = exec_sql(BackgroundSearchLog, search_rate_per_action_sql)
        %i(top result direct).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
          }
        end
      end

      def search_rate_per_action_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        if(a.total = 0, 0, a.top / a.total) top,
        if(a.total = 0, 0, a.result / a.total) result,
        if(a.total = 0, 0, a.direct / a.total) direct
      FROM (
        SELECT
          count(DISTINCT session_id) total,
          count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/?$', session_id, NULL)) top,
          count(DISTINCT if(referer regexp '^http://(www\.)?egotter\.com/searches', session_id, NULL)) result,
          count(DISTINCT if(referer = '', session_id, NULL)) direct
        FROM background_search_logs
        WHERE
          created_at BETWEEN :start AND :end
          AND device_type NOT IN ('crawler', 'UNKNOWN')
      ) a;
        SQL
      end

      def fetch_search_num_per_channel
        result = exec_sql(BackgroundSearchLog, search_num_per_channel_sql)
        result.map { |r| r.channel.to_s }.sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(blank))
          }
        end
      end

      def search_num_per_channel_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        if(channel = '', 'blank', channel) channel,
        count(*) total
      FROM background_search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY channel
      ORDER BY channel;
        SQL
      end

      def fetch_search_num_by_google
        result = exec_sql(SearchLog, search_num_by_google_sql)
        %i(not_search search).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend).to_f] }
          }
        end
      end

      def search_num_by_google_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(if(b.session_id IS NULL, 1, NULL)) not_search,
        count(if(b.session_id IS NOT NULL, 1, NULL)) search
      FROM (
        SELECT session_id
        FROM search_logs
        WHERE
          created_at BETWEEN :start AND :end
          AND device_type NOT IN ('crawler', 'UNKNOWN')
          AND action = 'new'
          AND referer regexp '^https?://(www\.)?google(\.com|\.co\.jp)'
      ) a LEFT OUTER JOIN (
        SELECT session_id
        FROM background_search_logs
        WHERE
          created_at BETWEEN :start AND :end
          AND device_type NOT IN ('crawler', 'UNKNOWN')
          AND referer regexp '^http://(www\.)?egotter\.com/?$'
      ) b ON (a.session_id = b.session_id);
        SQL
      end
    end
  end
end
