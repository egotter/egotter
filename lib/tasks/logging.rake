namespace :logging do
  desc 'find channel'
  task find_channel: :environment do
    log_klass =
      if ENV['LOG']
        [ENV['LOG'].constantize]
      else
        [SearchLog, BackgroundSearchLog, SignInLog, ModalOpenLog, CreateRelationshipLog]
      end

    Rails.logger.silence do
      log_klass.all? { |klass| import_channel!(klass) }
    end
  end

  def import_channel!(klass)
    finder = Class.new.extend(Concerns::Logging)
    now = Time.zone.now
    failed = false

    # Note that an index is not created on referral.
    klass.where.not(referral: '').find_in_batches(start: 1, batch_size: 10000) do |array|
      logs = array.map { |log| [log.id, finder.send(:find_channel, log.referral), now] }
      columns = %i(id channel created_at)

      if [BackgroundSearchLog, CreateRelationshipLog].include?(klass)
        logs.each { |log| log << '' }
        columns << 'message'
      end

      begin
        klass.import(columns, logs, validate: false, timestamps: false, on_duplicate_key_update: %i(channel))
        puts "#{Time.zone.now}: #{klass.name} #{logs.first[0]} - #{logs.last[0]}"
      rescue => e
        puts "#{e.class} #{e.message.slice(0, 100)}"
        failed = true
      end

      break if failed
    end

    !failed
  end
end
