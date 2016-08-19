module KpiAdmin
  module Kpis
    module PvUuHelper
      def fetch_uu
        result = exec_sql(SearchLog, uu_sql)
        %i(total guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def uu_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(user_id = -1, session_id, NULL)) guest,
        count(DISTINCT if(user_id != -1, session_id, NULL)) login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN');
        SQL
      end

      def fetch_uu_per_action
        result = exec_sql(SearchLog, uu_per_action_sql)
        result.map(&:action).sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: legend.in?(%w(removing removed))
          }
        end
      end

      def uu_per_action_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        action,
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY action
      ORDER BY action;
        SQL
      end

      def fetch_pv_per_action
        result = exec_sql(SearchLog, pv_per_action_sql)
        result.map { |r| r.action.to_s }.sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.action == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: legend.in?(%w(removing removed))
          }
        end
      end

      def pv_per_action_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        action,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action != 'waiting'
      GROUP BY action
      ORDER BY action;
        SQL
      end

      def fetch_uu_by_new_action
        result = exec_sql(SearchLog, uu_by_new_action_sql)
        %i(total guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def uu_by_new_action_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(DISTINCT session_id) total,
        count(DISTINCT if(user_id = -1, session_id, NULL)) guest,
        count(DISTINCT if(user_id != -1, session_id, NULL)) login
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'new';
        SQL
      end

      def fetch_pv_by_new_action
        result = exec_sql(SearchLog, pv_by_new_action_sql)
        %i(total guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def pv_by_new_action_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(if(user_id = -1, 1, NULL)) guest,
        count(if(user_id != -1, 1, NULL)) login,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
        AND action = 'new';
        SQL
      end

      def fetch_uu_per_device_type
        result = exec_sql(SearchLog, uu_per_device_type_sql)
        result.map(&:device_type).sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
          }
        end
      end

      def uu_per_device_type_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        device_type,
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY device_type
      ORDER BY device_type;
        SQL
      end

      def fetch_pv_per_device_type
        result = exec_sql(SearchLog, pv_per_device_type_sql)
        result.map(&:device_type).sort.uniq.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.device_type == legend }.map { |r| [to_msec_unixtime(r.date), r.total] }
          }
        end
      end

      def pv_per_device_type_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        device_type,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY device_type
      ORDER BY device_type;
        SQL
      end

      def fetch_uu_per_referer
        result = exec_sql(SearchLog, uu_per_referer_sql)
        result.map(&:_referer).uniq.sort.map do |legend|
          {
            name: legend,
            data: result.select { |r| r._referer == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(others egotter))
          }
        end
      end

      def uu_per_referer_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        case
          when referer regexp '^https?://(www\.)?egotter\.com' then 'egotter'
          when referer regexp '^https?://(www\.)?google\.com' then 'google.com'
          when referer regexp '^https?://(www\.)?google\.co\.jp' then 'google.co.jp'
          when referer regexp '^https?://(www\.)?google\.co\.in' then 'google.co.in'
          when referer regexp '^https?://search\.yahoo\.co\.jp' then 'search.yahoo.co.jp'
          when referer regexp '^https?://matome\.naver\.jp/(m/)?odai/2136610523178627801$' then 'matome.naver.jp'
          when referer regexp '^https?://((m|detail)\.)chiebukuro\.yahoo\.co\.jp' then 'chiebukuro.yahoo.co.jp'
          else 'others'
        end _referer,
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY _referer
      ORDER BY _referer;
        SQL
      end

      def fetch_pv_per_referer
        result = exec_sql(SearchLog, pv_per_referer_sql)
        result.map(&:_referer).uniq.sort.map do |legend|
          {
            name: legend,
            data: result.select { |r| r._referer == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(others egotter))
          }
        end
      end

      def pv_per_referer_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        case
          when referer regexp '^https?://(www\.)?egotter\.com' then 'egotter'
          when referer regexp '^https?://(www\.)?google\.com' then 'google.com'
          when referer regexp '^https?://(www\.)?google\.co\.jp' then 'google.co.jp'
          when referer regexp '^https?://(www\.)?google\.co\.in' then 'google.co.in'
          when referer regexp '^https?://search\.yahoo\.co\.jp' then 'search.yahoo.co.jp'
          when referer regexp '^https?://matome\.naver\.jp/(m/)?odai/2136610523178627801$' then 'matome.naver.jp'
          when referer regexp '^https?://((m|detail)\.)chiebukuro\.yahoo\.co\.jp' then 'chiebukuro.yahoo.co.jp'
          else 'others'
        end _referer,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY _referer
      ORDER BY _referer;
        SQL
      end

      def fetch_uu_per_channel
        result = exec_sql(SearchLog, uu_per_channel_sql)
        result.map(&:channel).uniq.sort.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(blank))
          }
        end
      end

      def uu_per_channel_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        if(channel = '', 'blank', channel) channel,
        count(DISTINCT session_id) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY channel
      ORDER BY channel;
        SQL
      end

      def fetch_pv_per_channel
        result = exec_sql(SearchLog, pv_per_channel_sql)
        result.map(&:channel).uniq.sort.map do |legend|
          {
            name: legend,
            data: result.select { |r| r.channel == legend }.map { |r| [to_msec_unixtime(r.date), r.total] },
            visible: !legend.in?(%w(blank))
          }
        end
      end

      def pv_per_channel_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        if(channel = '', 'blank', channel) channel,
        count(*) total
      FROM search_logs
      WHERE
        created_at BETWEEN :start AND :end
        AND device_type NOT IN ('crawler', 'UNKNOWN')
      GROUP BY channel
      ORDER BY channel;
        SQL
      end

      def fetch_new_user
        result = exec_sql(User, new_user_sql)
        %i(total).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def new_user_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(*) total
      FROM users
      WHERE created_at BETWEEN :start AND :end;
        SQL
      end

      def fetch_sign_in
        result = exec_sql(SignInLog, sign_in_sql)
        %i(NewUser ReturningUser).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.date), r.send(legend)] }
          }
        end
      end

      def sign_in_sql
        <<-'SQL'.strip_heredoc
      SELECT
        :label date,
        count(if(context = 'create', 1, NULL)) 'NewUser',
        count(if(context = 'update', 1, NULL)) 'ReturningUser'
      FROM sign_in_logs
      WHERE created_at BETWEEN :start AND :end;
        SQL
      end
    end
  end
end
