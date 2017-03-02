class ImportFriendsAndFollowersWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client
    retrying = false

    signatures = [
      {method: :user,      args: [uid]},
      {method: :friends,   args: [uid]},
      {method: :followers, args: [uid]}
    ]

    t_user = nil
    friends = followers = []
    ActiveRecord::Base.benchmark("[benchmark] #{self.class}#fetch friends and followers") do
      t_user, friends, followers = client._fetch_parallelly(signatures)
    end

    users = []

    ActiveRecord::Base.benchmark("[benchmark] #{self.class}#build friends") do
      users.concat(friends.map { |f| to_array(f) })
    end if friends&.any?

    ActiveRecord::Base.benchmark("[benchmark] #{self.class}#build followers") do
      users.concat(followers.map { |f| to_array(f) })
    end if followers&.any?

    users << to_array(t_user)
    users.uniq!(&:first)
    users.sort_by!(&:first)

    create_columns = %i(uid screen_name user_info friends_size followers_size)
    update_columns = %i(uid screen_name user_info)
    retrying = false
    begin
      ActiveRecord::Base.benchmark("[benchmark] #{self.class}#import TwitterDB::User") { Rails.logger.silence { ActiveRecord::Base.transaction {
        users.each_slice(1000) do |array|
          TwitterDB::User.import(create_columns, array, on_duplicate_key_update: update_columns, validate: false)
        end
      }}}
    rescue ActiveRecord::StatementInvalid => e
      if !retrying && e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        retrying = true
        retry
      end
      raise
    end

    retrying = false
    begin
      ActiveRecord::Base.benchmark("[benchmark] #{self.class}#import TwitterDB::Friendship and TwitterDB::Followership") { Rails.logger.silence { ActiveRecord::Base.transaction {
        TwitterDB::Friendship.import_from!(uid, friends.map(&:id)) if friends&.any?
        TwitterDB::Followership.import_from!(uid, followers.map(&:id)) if followers&.any?
        TwitterDB::User.find_by(uid: uid).tap { |me| me.update_columns(friends_size: me.friendships.size, followers_size: me.followerships.size) }
      }}}
    rescue ActiveRecord::StatementInvalid => e
      if !retrying && e.message.start_with?('Mysql2::Error: Deadlock found when trying to get lock; try restarting transaction')
        retrying = true
        retry
      end
      raise
    end

    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{t_user.screen_name}"

    ImportInactiveFriendsAndInactiveFollowersWorker.perform_async(user_id, uid) if friends&.any? || followers&.any?

  rescue Twitter::Error::Unauthorized => e
    case e.message
      when 'Invalid or expired token.' then User.find_by(id: user_id)&.update(authorized: false)
      when 'Could not authenticate you.' then logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
      else logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    end
  rescue ActiveRecord::StatementInvalid => e
    message = e.message.truncate(60)
    logger.warn "#{e.class} #{message} #{user_id} #{uid} #{retrying}"
    logger.info e.backtrace.join "\n"
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{user_id} #{uid} #{retrying}"
    logger.info e.backtrace.join "\n"
  end

  private

  def to_array(user)
    [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
  end
end
