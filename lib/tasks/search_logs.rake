namespace :search_logs do
  desc 'convert'
  task convert: :environment do
    start = (ENV['START'] || 1).to_i

    SearchLog.find_in_batches(start: start, batch_size: 1000) do |logs_array|
      logs = logs_array.map do |log|
        log.unify_referer
        log.unify_channel
        [log.id, log.unified_referer, log.unified_channel]
      end

      SearchLog.import(%i(id unified_referer unified_channel), logs, validate: false, on_duplicate_key_update: %i(unified_referer unified_channel))
    end
  end
end