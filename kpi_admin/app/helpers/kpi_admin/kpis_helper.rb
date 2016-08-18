module KpiAdmin
  module KpisHelper
    def placeholder_values(days)
      {
        start: days.first.beginning_of_day,
        end: days.last.end_of_day,
        label: days.last.beginning_of_day
      }
    end

    def show_sql(type, days)
      ActiveRecord::Base.send(:sanitize_sql_array, [send("#{type}_sql"), placeholder_values(days)])
    end

    def exec_sql(klass, sql)
      if sequence_number
        days = date_array[sequence_number]
        klass.find_by_sql([sql, placeholder_values(days)])
      else
        date_array.map { |days| klass.find_by_sql([sql, placeholder_values(days)]) }.flatten
      end
    end
  end
end
