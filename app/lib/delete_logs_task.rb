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

    100.times do |n|
      start_time = [min_time + n.days, max_time].min
      end_time = [min_time + (n + 1).days, max_time].min
      target_ids = []

      @klass.where(created_at: start_time..end_time).select(:id).find_in_batches do |records|
        next if records.empty?
        target_ids << records.map(&:id)
      end

      target_ids.each do |ids|
        @klass.where(id: ids).delete_all
        print '.'
      end

      break if start_time >= max_time
    end
  end
end
