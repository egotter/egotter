namespace :users do
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
