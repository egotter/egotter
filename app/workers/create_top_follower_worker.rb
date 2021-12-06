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
    if (top_follower = find_top_follower(twitter_user.follower_uids))
      twitter_user.update(top_follower_uid: top_follower.uid)
    end
  rescue => e
    Airbag.warn "#{e.inspect} twitter_user_id=#{twitter_user_id} options=#{options.inspect}"
    Airbag.info e.backtrace.join("\n")
  end

  private

  def find_top_follower(uids)
    candidates = []

    uids.each_slice(1000) do |uids_array|
      candidates << TwitterDB::User.where(uid: uids_array).select(:uid, :followers_count).order(followers_count: :desc).first
    end

    candidates.compact.max_by(&:followers_count)
  end
end
