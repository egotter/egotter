class ImportFriendsAndFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client

    signatures = [
      {method: :user,      args: [uid]},
      {method: :friends,   args: [uid]},
      {method: :followers, args: [uid]}
    ]

    # This process takes a few seconds.
    t_user, friends, followers = client._fetch_parallelly(signatures)
    users = []

    ActiveRecord::Base.benchmark("benchmark #{self.class}#build friends") do
      users =
        friends.map do |friend|
          [friend.id, friend.screen_name, friend.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
        end if friends&.any?
    end

    ActiveRecord::Base.benchmark("benchmark #{self.class}#build followers") do
      users +=
        followers.map do |follower|
          [follower.id, follower.screen_name, follower.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
        end if followers&.any?
    end

    user_info = t_user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json
    users << [uid, t_user.screen_name, user_info, -1, -1]

    ActiveRecord::Base.benchmark("benchmark #{self.class}#import TwitterDB::User") { Rails.logger.silence { ActiveRecord::Base.transaction {
      users.uniq(&:first).each_slice(1000) do |array|
        TwitterDB::User.import(%i(uid screen_name user_info friends_size followers_size), array, on_duplicate_key_update: %i(uid screen_name user_info), validate: false)
      end
    }}}

    ActiveRecord::Base.benchmark("benchmark #{self.class}#import TwitterDB::Friendship and TwitterDB::Followership") { Rails.logger.silence { ActiveRecord::Base.transaction {
      TwitterDB::Friendship.import_from!(uid, friends.map(&:id)) if friends&.any?
      TwitterDB::Followership.import_from!(uid, followers.map(&:id)) if followers&.any?

      TwitterDB::User.find_by(uid: uid).tap { |me| me.update_columns(friends_size: me.friendships.size, followers_size: me.followerships.size) }
    }}}

    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{t_user.screen_name}"

  rescue => e
    message = e.message.truncate(200)
    logger.warn "#{self.class}: #{e.class} #{message} #{user_id} #{uid}"
    logger.info e.backtrace.join "\n"
  end
end
