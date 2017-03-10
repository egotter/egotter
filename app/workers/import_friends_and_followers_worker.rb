class ImportFriendsAndFollowersWorker
  include Sidekiq::Worker
  include Concerns::WorkerUtils
  sidekiq_options queue: self, retry: false, backtrace: false

  def perform(user_id, uid)
    started_at = Time.zone.now
    chk1 = chk2 = nil
    client = user_id == -1 ? Bot.api_client : User.find(user_id).api_client
    @retry_count = 0

    signatures = [{method: :user, args: [uid]}, {method: :friends, args: [uid]}, {method: :followers, args: [uid]}]
    t_user, friends, followers = client._fetch_parallelly(signatures)
    users = []

    _benchmark('build friends') { users.concat(friends.map { |f| to_array(f) }) }
    _benchmark('build followers') { users.concat(followers.map { |f| to_array(f) }) }

    users << to_array(t_user)
    users.uniq!(&:first)
    users.sort_by!(&:first)

    chk1 = Time.zone.now
    _retry_with_transaction!('import TwitterDB::User') { TwitterDB::User.import_each_slice(users) }

    friend_ids = friends.map(&:id)
    follower_ids = followers.map(&:id)

    chk2 = Time.zone.now
    _retry_with_transaction!('import TwitterDB::Friendship and TwitterDB::Followership') do
      TwitterDB::Friendship.import_from!(uid, friend_ids)
      TwitterDB::Followership.import_from!(uid, follower_ids)
      TwitterDB::User.find_by(uid: uid).update!(friends_size: friend_ids.size, followers_size: follower_ids.size)
    end

  rescue Twitter::Error::Unauthorized => e
    case e.message
      when 'Invalid or expired token.' then User.find_by(id: user_id)&.update(authorized: false)
      when 'Could not authenticate you.' then logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
      else logger.warn "#{e.class} #{e.message} #{user_id} #{uid}"
    end
  rescue ActiveRecord::StatementInvalid => e
    logger.warn "Deadlock found when trying to get lock #{user_id} #{uid} #{@retry_count} start: #{short_hour(started_at)} chk1: #{short_hour(chk1)} chk2: #{short_hour(chk2)} finish: #{short_hour(Time.zone.now)}"
    logger.info e.backtrace.join "\n"
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{e.class} #{message} #{user_id} #{uid} #{@retry_count}"
    logger.info e.backtrace.join "\n"
  ensure
    Rails.logger.info "[worker] #{self.class} finished. #{user_id} #{uid} #{t_user&.screen_name}"
  end

  private

  def to_array(user)
    [user.id, user.screen_name, user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, -1, -1]
  end
end
