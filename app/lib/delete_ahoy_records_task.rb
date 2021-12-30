class DeleteAhoyRecordsTask
  def initialize(klass, year, month, options = {})
    @klass = klass
    @year = year
    @month = month
    @column = klass == Ahoy::Event ? :time : :started_at
    Rails.logger.level = :debug
  end

  def start
    time = Time.zone.parse("#{@year}-#{@month}-01")
    min_time = time.beginning_of_month
    max_time = time.end_of_month
    total = @klass.where(@column => min_time..max_time).size

    return if total == 0

    @progress = Progress.new(total: total * 2)
    @sigint = Sigint.new.trap

    100.times do |n|
      start_time = [min_time + n.days, max_time].min
      end_time = [min_time + (n + 1).days, max_time].min

      ids = collect_ids(start_time, end_time)
      delete_records(ids)

      break if start_time >= max_time || @sigint.trapped?
    end
  end

  def collect_ids(start_time, end_time)
    query = @klass.from("#{@klass.table_name} USE INDEX(index_#{@klass.table_name}_on_#{@column})").
        where(@column => start_time..end_time)
    ids = []
    total = query.size

    query.select(:id).find_in_batches(batch_size: 10000) do |records|
      ids.concat(records.map(&:id))
      @progress.increment(records.size, "(collecting #{ids.size}/#{total} ids)")
      break if @sigint.trapped?
    end

    ids
  end

  def delete_records(ids)
    total = ids.size
    deleted_count = 0

    ids.each_slice(1000) do |ids_array|
      @klass.where(id: ids_array).delete_all
      @progress.increment(ids_array.size, "(deleting #{deleted_count += ids_array.size}/#{total} records)")
      break if @sigint.trapped?
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
