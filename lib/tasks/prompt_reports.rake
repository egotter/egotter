namespace :prompt_reports do
  desc 'send'
  task send: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    deadline =
      case
        when ENV['DEADLINE'].blank? then nil
        when ENV['DEADLINE'].match(/\d+\.(minutes?|hours?)/) then Time.zone.now + eval(ENV['DEADLINE'])
        else Time.zone.parse(ENV['DEADLINE'])
      end

    user_ids = ENV['USER_IDS']
    user_ids =
      case
        when user_ids.blank? then 1..User.maximum(:id)
        when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
        when user_ids.include?(',') then user_ids.remove(' ').split(',').map(&:to_i)
        else [user_ids.to_i]
      end

    ids = {specified: user_ids}
    ids[:authorized] = User.where(id: ids[:specified], authorized: true).pluck(:id)
    ids[:active] = User.active(14).where(id: ids[:authorized]).pluck(:id)
    ids[:sendable] = User.can_send_dm.where(id: ids[:active]).pluck(:id)

    start_time = Time.zone.now
    reports_count = PromptReport.all.size
    users_count = User.all.size
    puts "\nstarted:"
    puts %Q(  start: #{start_time}#{", deadline: #{deadline}" if deadline}, reports: #{reports_count}, users: #{users_count} #{ids.map { |k, v| "#{k}: #{v.size}" }.join(', ')}\n\n)

    processed = 0
    fatal = false
    errors = []

    ids[:sendable].each.with_index do |user_id, i|
      begin
        Rails.logger.silence(Logger::WARN) { CreatePromptReportWorker.new.perform(user_id) }
      rescue => e
        errors << {time: Time.zone.now, user_id: user_id, error_class: e.class, error_message: e.message}
        fatal = errors.size >= processed / 10
      end
      processed += 1

      if i % 100 == 0
        avg = "#{'avg %4.1f' % ((Time.zone.now - start_time) / (i + 1))} seconds"
        elapsed = "#{'elapsed %.1f' % (Time.zone.now - start_time)} seconds"
        remaining = deadline ? ", remaining #{'%.1f' % (deadline - Time.zone.now)} seconds" : ''
        puts "#{Time.zone.now}: #{user_id}, #{avg}, #{elapsed}#{remaining}"
      end

      break if (deadline && Time.zone.now > deadline) || sigint || fatal
    end

    if errors.any?
      puts "\nerrors:"
      errors.each { |error| puts "  #{error[:time]}: #{error[:user_id]}, #{error[:error_class]} #{error[:error_message]}" }
    end

    new_reports_count = PromptReport.all.size

    puts "\n#{(sigint || fatal ? 'suspended:' : 'finished:')}"
    puts %Q(  start: #{start_time}, finish: #{Time.zone.now}#{", deadline: #{deadline}" if deadline}, reports: #{new_reports_count}, users: #{users_count}, #{ids.map { |k, v| "#{k}: #{v.size}" }.join(', ')}, processed: #{processed}, send: #{new_reports_count - reports_count}, errors: #{errors.size}\n\n)
  end
end
