namespace :banned_users do
  task destroy: :environment do
    user = User.find_by!(uid: ENV['UID'])
    puts "screen_name=#{user.screen_name}"

    if ENV['FORCE']
      BannedUser.find_by!(user_id: user.id).destroy
    else
      DestroyBannedUserTask.new(user, dry_run: ENV['DRY_RUN'])
    end
  end
end
