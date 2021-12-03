class DeleteAhoyRecordsTask
  def initialize(klass, start_time, end_time, options = {})
    @klass = klass
    @start_time = start_time
    @end_time = end_time
    @column = klass == Ahoy::Event ? :time : :started_at
  end

  def start
    total = @klass.where(@column => @start_time..@end_time).size
    puts "Delete #{total} records"
    return if total == 0

    sigint = Sigint.new.trap
    count = 0
    stopped = false

    (24 * 30).times do |i|
      start_time = @start_time + i.hours
      end_time = @start_time + (i + 1).hours
      if end_time > @end_time
        end_time = @end_time
        stopped = true
      end
      query = @klass.where(@column => start_time..end_time).select(:id)
      ids_array = []

      query.find_in_batches do |records|
        ids_array << records.map(&:id)
      end

      ids_array.each do |ids|
        @klass.where(id: ids).delete_all
        count += ids.size
        print "\r#{(100 * count.to_f / total).round(1)}%"
      end

      return if stopped || sigint.trapped?
    end

    puts ''
  end
end
