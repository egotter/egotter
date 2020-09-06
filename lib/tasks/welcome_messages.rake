namespace :welcome_messages do
  desc 'Resend'
  task resend: :environment do
    user_ids = ENV['USER_IDS'].split(',').map(&:to_i)
    prefix = ENV['PREFIX']&.gsub(/\\n/, "\n")
    processed = 0
    failed = 0

    user_ids.each do |user_id|
      begin
        message = WelcomeMessage.welcome(user_id)
        message.set_prefix_message(prefix) if prefix
        message.deliver!
        processed += 1
      rescue => e
        puts "#{e.inspect} user_id=#{user_id}"
        failed += 1
      end

    end

    puts "processed=#{processed} failed=#{failed}"
  end
end
