namespace :forbidden_users do
  desc 'update uid'
  task update_uid: :environment do
    ForbiddenUser.update_uid_batch
  end
end
