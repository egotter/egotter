require 'active_support/concern'

module Concerns::DeletableLog
  extend ActiveSupport::Concern

  class_methods do
    def delete_old_logs(year, month)
      first_log = order(created_at: :asc).first
      if first_log.nil?
        puts "#{table_name} is empty table"
        return
      end

      if year.blank? || month.blank?
        time = first_log.created_at
      else
        time = Time.zone.now.change(year: year, month: month)
      end

      start_time = time.beginning_of_month.to_s(:db)
      end_time = time.end_of_month.to_s(:db)
      puts "start_time=#{start_time} end_time=#{end_time}"

      logs = where(created_at: start_time..end_time).select(:id)
      logs_count = logs.find_in_batches(batch_size: 100_000).lazy.map(&:size).sum
      puts "Delete #{logs_count} records from #{table_name}"

      if logs.any?
        logs.find_in_batches(batch_size: 100_000) do |logs_array|
          where(id: logs_array.map(&:id)).delete_all
          print '.'
        end
      end
    end
  end
end
