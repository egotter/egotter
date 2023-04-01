namespace :users do
  task invalidate_credentials: :environment do
    processed_count = 0
    @sigint = Sigint.new.trap

    User.authorized.select(:id).find_in_batches(batch_size: 10) do |users|
      break if @sigint.trapped?
      users.each { |user| UpdateUserAttrsWorker.perform_async(user.id) }
      processed_count += users.size
      print '.' if processed_count % 1000 == 0
      sleep users.size / 10.0 * 2.0
    end

    puts "Processed #{processed_count}"
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
