class DeleteLogsTask
  def initialize(klass, year, month, options = {})
    @klass = klass
    @year = year
    @month = month
  end

  def start
    time = Time.zone.now.change(year: @year, month: @month)
    min_time = time.beginning_of_month
    max_time = time.end_of_month
    progress = Progress.new(total: @klass.where(created_at: min_time..max_time).size * 2)
    sigint = Sigint.new.trap

    100.times do |n|
      start_time = [min_time + n.days, max_time].min
      end_time = [min_time + (n + 1).days, max_time].min
      target_ids = []

      @klass.from("#{@klass.table_name} USE INDEX(index_#{@klass.table_name}_on_created_at)").
          where(created_at: start_time..end_time).select(:id).find_in_batches do |records|
        next if records.empty?
        target_ids << records.map(&:id)
        progress.increment(records.size, '(collecting ids)')
        break if sigint.trapped?
      end

      target_ids.each do |ids|
        @klass.where(id: ids).delete_all
        progress.increment(ids.size, '(deleting records)')
        break if sigint.trapped?
      end

      break if start_time >= max_time || sigint.trapped?
    end
  end

  class Progress
    def initialize(total:)
      @total = total
      @count = 0
      @output = $stdout
    end

    def increment(count, message = nil)
      @count += count
      print(message)
    end

    def progress(count, message = nil)
      @count = count
      print(message)
    end

    def finish
      @output.puts '100.0%'
    end

    private

    def print(message)
      @output.print "\r#{(100 * @count.to_f / @total).round(1)}% #{message}"
    end
  end
end
