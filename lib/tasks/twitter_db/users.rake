namespace :twitter_db do
  namespace :users do
    desc 'create TwitterDB::User'
    task create: :environment do
      uids = ENV['UIDS'].remove(' ').split(',').map(&:to_i)
      CreateTwitterDBUserWorker.perform_async(uids)
    end

    desc 'Update friends_count and followers_count'
    task update_friends_count: :environment do
      sigint = Util::Sigint.new.trap
      start = ENV['START'] ? ENV['START'].to_i : 1

      users = []

      TwitterDB::User.find_each(start: start, batch_size: 1000) do |user|
        if user._user_info[:screen_name] == 'suspended' && user._user_info[:description] == ''
          next
        end

        user.assign_attributes(
            friends_count: user._user_info[:friends_count],
            followers_count: user._user_info[:followers_count]
        )

        if user.friends_count_changed? || user.followers_count_changed?
          users << user
        end

        if users.size >= 1000
          columns = %i(uid screen_name friends_count followers_count user_info created_at updated_at)
          users = users.map {|user| user.slice(*columns).values}

          TwitterDB::User.import(columns, users, on_duplicate_key_update: columns, batch_size: 1, validate: false, timestamps: false)

          users.clear
        end

        if sigint.trapped?
          puts "current id #{user.id}"
          break
        end
      end
    end
  end
end
