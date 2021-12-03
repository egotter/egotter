class DeleteAhoyRecordsTask
  # options:
  #   loop_count
  #   time_range
  def initialize(klass, start_time, end_time, options = {})
    @klass = klass
    @start_time = start_time
    @end_time = end_time
    @column = klass == Ahoy::Event ? :time : :started_at
    @loop_count = options[:loop_count]
    @time_range = options[:time_range]
  end

  def start
    total = @klass.where(@column => @start_time..@end_time).size
    puts "Delete #{total} records"
    return if total == 0

    sigint = Sigint.new.trap
    count = 0
    stopped = false
    if total > 5_000_000
      loop_count = @loop_count || 30 * 24 * 60
      time_range = @time_range || 1.minute
    else
      loop_count = @loop_count || 30 * 24
      time_range = @time_range || 1.hour
    end

    puts "Time range is #{time_range}"
    puts "Loop count is #{loop_count}"
    progress = Progress.new(total: total * 2)

    loop_count.times do |i|
      start_time = @start_time + i * time_range
      end_time = @start_time + (i + 1) * time_range
      if end_time > @end_time
        end_time = @end_time
        stopped = true
      end
      query = @klass.where(@column => start_time..end_time).select(:id)
      ids_array = []

      query.find_in_batches do |records|
        ids_array << records.map(&:id)

        progress.progress(count += records.size, '(collecting ids)')
        break if sigint.trapped?
      end

      ids_array.each do |ids|
        @klass.where(id: ids).delete_all

        progress.progress(count += ids.size, '(deleting records)')
        break if sigint.trapped?
      end

      break if stopped || sigint.trapped?
    end

    puts ''
  end

  class Progress
    def initialize(total:)
      @total = total
      @output = $stdout
    end

    def progress(count, message = nil)
      @output.print "\r#{(100 * count.to_f / @total).round(1)}% #{message}"
    end

    def finish
      @output.puts '100.0%'
    end
  end
end
