require 'active_support/concern'

module DeletableLog
  extend ActiveSupport::Concern

  class_methods do
    def delete_old_logs(year, month)
      unless File.basename($0) == 'rake'
        raise "Don't call #{self}##{__method__} outside Rake tasks"
      end

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

      sigint = Sigint.new.trap

      logs = where(created_at: start_time..end_time).select(:id)
      puts "Delete #{logs.size} records from #{table_name}"

      return if sigint.trapped?

      if logs.size > 0
        logs.find_in_batches(batch_size: 1000) do |logs_array|
          where(id: logs_array.map(&:id)).delete_all
          print '.'

          return if sigint.trapped?
        end
      end
    end
  end
end
