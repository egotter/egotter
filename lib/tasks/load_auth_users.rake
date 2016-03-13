namespace :load_auth_users do
  desc 'Load AuthUsers'
  task run: :environment do
    LoadAuthUsers.new.run
  end
end
