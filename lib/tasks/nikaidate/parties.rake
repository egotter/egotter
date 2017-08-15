namespace :nikaidate do
  namespace :parties do
    desc 'create'
    task create: :environment do

      Nikaidate::Party.find_each do |user|
        uid = user.uid.to_i
        client = Bot.api_client
        t_user = client.user(uid)

        if t_user.friends_count + t_user.followers_count <= 5000
          signatures = [{method: :friend_ids,   args: [uid]}, {method: :follower_ids, args: [uid]}]
          friend_uids, follower_uids = client._fetch_parallelly(signatures)

          TwitterDB::Users.fetch_and_import((friend_uids + follower_uids).uniq, client: client)

          ActiveRecord::Base.transaction do
            TwitterDB::User.find_or_initialize_by(uid: uid).update!(screen_name: t_user.screen_name, user_info: TwitterUser.collect_user_info(t_user), friends_size: friend_uids.size, followers_size: follower_uids.size)
            TwitterDB::Friendships.import(uid, friend_uids, follower_uids)
          end

          puts "Created #{t_user.id} #{friend_uids.size} #{follower_uids.size}"
        else
          puts "Too many friends #{t_user.uid}"
        end
      end
    end

    desc 'update_ranking'
    task update_ranking: :environment do
      Nikaidate::Party.find_each do |user|
        user.update!(citations_count: user.opinions.map(&:posts).map(&:size).sum)
        puts "#{user.uid} #{user.citations_count}"
      end

      Nikaidate::Party.select(:id, :uid, :citations_count).order(citations_count: :desc).each.with_index do |user, i|
        user.update!(rank: i + 1)
      end
    end

  end
end
