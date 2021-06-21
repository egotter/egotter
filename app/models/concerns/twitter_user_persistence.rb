require 'active_support/concern'

module TwitterUserPersistence
  extend ActiveSupport::Concern

  included do
    attr_accessor :copied_friend_uids, :copied_follower_uids, :copied_user_timeline, :copied_mention_tweets, :copied_favorite_tweets

    after_create :perform_before_commit
    after_create_commit :perform_after_commit
  end

  # This method is called manually
  def perform_before_transaction!
    bm_start!

    if copied_user_timeline&.is_a?(Array)
      bm_record('InMemory::StatusTweet') do
        InMemory::StatusTweet.import_from(uid, copied_user_timeline)
      end
    end

    if copied_favorite_tweets&.is_a?(Array)
      bm_record('InMemory::FavoriteTweet') do
        InMemory::FavoriteTweet.import_from(uid, copied_favorite_tweets)
      end
    end

    if copied_mention_tweets&.is_a?(Array)
      bm_record('InMemory::MentionTweet') do
        InMemory::MentionTweet.import_from(uid, copied_mention_tweets)
      end
    end
  ensure
    bm_finish!('before_transaction')
  end

  # WARNING: Don't create threads in this method!
  def perform_before_commit
    bm_start!

    bm_record('InMemory::TwitterUser') do
      InMemory::TwitterUser.import_from(id, uid, screen_name, profile_text, copied_friend_uids, copied_follower_uids)
    end
  rescue => e
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} twitter_user=#{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise ActiveRecord::Rollback
  ensure
    bm_finish!('before_commit')
  end

  def perform_after_commit
    data = {
        id: id,
        uid: uid,
        screen_name: screen_name,
        profile: profile_text,
        friend_uids: copied_friend_uids,
        follower_uids: copied_follower_uids,
        status_tweets: copied_user_timeline,
        favorite_tweets: copied_favorite_tweets,
        mention_tweets: copied_mention_tweets,
    }
    data = Base64.encode64(Zlib::Deflate.deflate(data.to_json))
    PerformAfterCommitWorker.perform_async(id, data)
  end

  def bm_start!
    @bm_persistence = {}
    @bm_persistence_start = Time.zone.now
  end

  def bm_record(message)
    start = Time.zone.now
    yield
    @bm_persistence[message] = Time.zone.now - start if @bm_persistence
  end

  def bm_finish!(name)
    elapsed = Time.zone.now - @bm_persistence_start
    @bm_persistence['sum'] = @bm_persistence.values.sum
    @bm_persistence['elapsed'] = elapsed
    @bm_persistence.transform_values! { |v| sprintf("%.3f", v) }

    logger.info "Benchmark CreateTwitterUserRequest #{name} twitter_user=#{id} user_id=#{user_id} uid=#{uid} #{@bm_persistence.inspect}"
    @bm_persistence = nil
  rescue => e
    logger.warn "Benchmark CreateTwitterUserRequest failed #{e.inspect}"
  end
end
