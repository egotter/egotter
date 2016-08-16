module KpiAdmin
  module Kpis
    module MonthlyHelper
      def fetch_mau
        result = SearchLog.find_by_sql([mau_sql, {start: date_start, end: date_end}])
        %i(total guest login).map do |legend|
          {
            name: legend,
            data: result.map { |r| [to_msec_unixtime(r.month), r.send(legend)] }
          }
        end
      end

      def mau_sql
        <<-'SQL'.strip_heredoc
          SELECT
            DATE_FORMAT(created_at, '%Y-%m-01') month,
            count(DISTINCT session_id) total,
            count(DISTINCT if(user_id = -1, session_id, NULL)) guest,
            count(DISTINCT if(user_id != -1, session_id, NULL)) login
          FROM search_logs
          WHERE
            created_at BETWEEN :start AND :end
            AND device_type NOT IN ('crawler', 'UNKNOWN')
          GROUP BY DATE_FORMAT(created_at, '%Y-%m-01')
          ORDER BY DATE_FORMAT(created_at, '%Y-%m-01');
        SQL
      end
    end
  end
end
