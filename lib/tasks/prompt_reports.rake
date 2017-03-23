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
        when ENV['DEADLINE'].nil? then nil
        when ENV['DEADLINE'].match(/\d+\.(minutes?|hours?)/) then Time.zone.now + eval(ENV['DEADLINE'])
        else Time.zone.parse(ENV['DEADLINE'])
      end

    user_ids = ENV['USER_IDS']
    user_ids =
      case
        when user_ids.blank? then 1..User.maximum(:id)
        when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
        when user_ids.include?(',') then user_ids.split(',').map(&:to_i)
        else [user_ids.to_i]
      end

    authorized = User.authorized.where(id: user_ids).pluck(:id)
    active = User.active(14).where(id: authorized).pluck(:id)

    start_time = Time.zone.now
    puts "\nstarted:"
    puts %Q(  start: #{start_time}#{", deadline: #{deadline}" if deadline}, user_ids: #{user_ids.size}, authorized: #{authorized.size}, active: #{active.size}\n\n)

    processed = 0
    fatal = false
    errors = []

    active.each.with_index do |user_id, i|
      failed = false
      begin
        CreatePromptReportWorker.new.perform(user_id)
      rescue => e
        failed = true
        errors << {time: Time.zone.now, error: e, user_id: user_id}
        fatal = errors.size >= processed / 10
      end
      processed += 1

      if i % 100 == 0
        avg = "#{'%4.1f' % ((Time.zone.now - start_time) / (i + 1))} seconds/user"
        elapsed = "#{'%.1f' % (Time.zone.now - start_time)} seconds elapsed"
        remaining = deadline ? ", #{'%.1f' % (deadline - Time.zone.now)} seconds remaining" : ''
        puts "#{Time.zone.now}: #{user_id}, #{avg}, #{elapsed}#{remaining}"
      end

      break if (deadline && Time.zone.now > deadline) || sigint || fatal
    end

    if errors.any?
      puts "\nerrors:"
      errors.each { |error| puts "  #{error[:time]}: #{error[:user_id]}, #{error[:error].class} #{error[:error].message}" }
    end

    puts "\n#{(sigint || fatal ? 'suspended:' : 'finished:')}"
    puts "  start: #{start_time}, finish: #{Time.zone.now}, processed: #{processed}"
  end
end
