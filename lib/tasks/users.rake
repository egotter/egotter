namespace :users do
  task invalidate_credentials: :environment do
    start_id = ENV['START_ID']&.to_i || 1
    batch_size = ENV['BATCH_SIZE']&.to_i || 100
    processed_count = 0
    @sigint = Sigint.new.trap
    last_record = nil

    User.authorized.select(:id).find_in_batches(start: start_id, batch_size: batch_size) do |users|
      last_record = users.first
      break if @sigint.trapped?
      users.each { |user| UpdateUserAttrsWorker.perform_async(user.id) }
      processed_count += users.size
      print '.' if processed_count % (batch_size * 10) == 0
      batch_size.times do
        break if Sidekiq::Queue.new('misc').size < 10
        sleep 1
      end
    end

    puts "Processed #{processed_count} start_id #{start_id} last_id #{last_record&.id}"
  end

  task update_credential_token: :environment do
    processed_count = 0
    User.includes(:credential_token).references(:credential_token).authorized.where('users.token != credential_tokens.token').find_each do |user|
      user.credential_token.update!(token: user.token, secret: user.secret)
      processed_count += 1
      print '.' if processed_count % 1000 == 0
    end
    puts "processed #{processed_count}"
  end
end
