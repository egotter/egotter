namespace :twitter_users do
  task verify: :environment do |task|
    users = TwitterUser.select(:id, :uid, :created_at).where('created_at > ?', (1.hour + 5.minutes).ago)
    interval = TwitterUser::CREATE_RECORD_INTERVAL / 2
    result = []

    users.find_each do |user|
      query = TwitterUser.where(uid: user.uid).where(created_at: (user.created_at - interval)..(user.created_at + interval))
      if query.size > 1
        result << user.id
      end
    end

    if result.any?
      puts "#{Time.zone.now.to_s(:db)} task=#{task.name} Invalid data #{result}"
    end

    puts "#{Time.zone.now.to_s(:db)} task=#{task.name} total=#{users.size}"
  end
end
