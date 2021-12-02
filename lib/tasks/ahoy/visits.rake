namespace :ahoy do
  namespace :visits do
    task delete: :environment do
      start_time = Time.zone.parse(ENV['SINCE'])
      end_time = Time.zone.parse(ENV['UNTIL'])

      query = Ahoy::Visit.where(started_at: start_time..end_time).select(:id)
      puts "Delete #{query.size} records"

      sigint = Sigint.new.trap

      query.find_in_batches do |records|
        Ahoy::Visit.where(id: records.map(&:id)).delete_all
        print '.'

        return if sigint.trapped?
      end
    end
  end
end
