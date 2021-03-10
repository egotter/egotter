class DeleteLogsTask
  def initialize(klass, year, month, options = {})
    @klass = klass
    @year = year
    @month = month
  end

  def start!
    if !Rails.env.test? && File.basename($0) != 'rake'
      raise "Don't call #{self}##{__method__} outside Rake tasks"
    end

    first_log = @klass.order(created_at: :asc).first
    if first_log.nil?
      puts "The #{@klass.table_name} table is empty"
      return
    end

    if @year.blank? || @month.blank?
      time = first_log.created_at
    else
      time = Time.zone.now.change(year: @year, month: @month)
    end

    start_time = time.beginning_of_month.to_s(:db)
    end_time = time.end_of_month.to_s(:db)
    puts "start_time=#{start_time} end_time=#{end_time}"

    sigint = Sigint.new.trap

    logs = @klass.where(created_at: start_time..end_time).select(:id)
    puts "Delete #{logs.size} records from #{@klass}"

    return if sigint.trapped?

    if logs.size > 0
      logs.find_in_batches(batch_size: 1000) do |logs_array|
        @klass.where(id: logs_array.map(&:id)).delete_all
        print '.'

        return if sigint.trapped?
      end
    end
  end
end
