namespace :ahoy do
  namespace :events do
    task delete: :environment do
      start_time = Time.zone.parse(ENV['SINCE'])
      end_time = Time.zone.parse(ENV['UNTIL'])

      query = Ahoy::Event.where(time: start_time..end_time).select(:id)
      total = query.size
      puts "Delete #{total} records"

      sigint = Sigint.new.trap
      count = 0

      query.find_in_batches do |records|
        Ahoy::Event.where(id: records.map(&:id)).delete_all
        count += records.size
        print "\r#{(100 * count.to_f / total).round(1)}%"

        return if sigint.trapped?
      end

      puts ''
    rescue => e
      puts e.inspect
    end
  end
end
