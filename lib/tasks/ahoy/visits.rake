namespace :ahoy do
  namespace :visits do
    task delete: :environment do
      start_time = Time.zone.parse(ENV['SINCE'])
      end_time = Time.zone.parse(ENV['UNTIL'])

      query = Ahoy::Visit.where(started_at: start_time..end_time).select(:id)
      total = query.size
      puts "Delete #{total} records"

      sigint = Sigint.new.trap
      count = 0

      query.find_in_batches do |records|
        Ahoy::Visit.where(id: records.map(&:id)).delete_all
        count += records.size
        print "\r#{(100 * count.to_f / total).round(1)}%"

        return if sigint.trapped?
      end

      puts ''
    end
  end
end
