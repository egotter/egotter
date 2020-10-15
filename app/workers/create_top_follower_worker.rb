class CreateTopFollowerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'misc', retry: 0, backtrace: false

  def unique_key(twitter_user_id, options = {})
    twitter_user_id
  end

  def unique_in
    1.minute
  end

  def expire_in
    10.minutes
  end

  # options:
  def perform(twitter_user_id, options = {})
    twitter_user = TwitterUser.find(twitter_user_id)
    follower_uids = twitter_user.follower_uids
    candidates = []

    follower_uids.each_slice(1000) do |uids_array|
      candidates << TwitterDB::User.where(uid: uids_array).group(:uid).select('uid, max(followers_count) followers_count').order(followers_count: :desc).first
    end

    top_follower = candidates.compact.max_by { |user| user.followers_count }
    twitter_user.update(top_follower_uid: top_follower.uid) if top_follower
  rescue => e
    logger.warn "#{e.inspect} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    logger.info e.backtrace.join("\n")
  end
end
