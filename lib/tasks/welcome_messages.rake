namespace :welcome_messages do
  desc 'Resend'
  task resend: :environment do
    user_ids = ENV['USER_IDS'].split(',').map(&:to_i)
    prefix = ENV['PREFIX']&.gsub(/\\n/, "\n")

    user_ids.each do |user_id|
      CreateWelcomeMessageWorker.perform_async(user_id, prefix: prefix)
    end
  end
end
