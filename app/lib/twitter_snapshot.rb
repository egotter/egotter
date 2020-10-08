class TwitterSnapshot
  attr_accessor :user_id
  attr_reader :friend_uids, :follower_uids, :user_timeline, :mention_tweets, :favorite_tweets

  def initialize(user)
    @user = user
    @friend_uids = []
    @follower_uids = []
    @user_timeline = []
    @mention_tweets = []
    @favorite_tweets = []
  end

  def uid
    @user[:id]
  end

  def screen_name
    @user[:screen_name]
  end

  def friends_count
    @user[:friends_count]
  end

  def followers_count
    @user[:followers_count]
  end

  def friend_uids=(value)
    @friend_uids = value if value&.any?
  end

  def friends_size
    @friend_uids.size
  end

  def follower_uids=(value)
    @follower_uids = value if value&.any?
  end

  def followers_size
    @follower_uids.size
  end

  def [](key)
    if %i(friends_count followers_count).include?(key)
      @user[key]
    elsif key == :friend_uids
      @friend_uids
    elsif key == :follower_uids
      @follower_uids
    else
      raise "Invalid key value=#{key}"
    end
  end

  def profile_text
    @user.symbolize_keys.slice(*TwitterUserProfile::SAVE_KEYS).to_json
  end

  def user_timeline=(value)
    @user_timeline = value.map { |tweet| collect_tweet_attrs(tweet) } if value&.any?
  end

  def mention_tweets=(value)
    @mention_tweets = value.map { |tweet| collect_tweet_attrs(tweet) } if value&.any?
  end

  def favorite_tweets=(value)
    @favorite_tweets = value.map { |tweet| collect_tweet_attrs(tweet) } if value&.any?
  end

  def copy
    TwitterUser.new(
        user_id: user_id,
        uid: uid,
        screen_name: screen_name,
        friends_count: friends_count,
        followers_count: followers_count,
        profile_text: profile_text,
        friends_size: friends_size,
        followers_size: followers_size,
        copied_friend_uids: friend_uids,
        copied_follower_uids: follower_uids,
        copied_user_timeline: user_timeline,
        copied_mention_tweets: mention_tweets,
        copied_favorite_tweets: favorite_tweets
    )
  end

  def too_little_friends?
    friends_count == 0 && followers_count == 0 && friends_size == 0 && followers_size == 0
  end

  # Reason1: too many friends
  # Reason2: near zero friends
  def no_need_to_import_friendships?
    friends_size == 0 && followers_size == 0
  end

  private

  def collect_tweet_attrs(tweet)
    TwitterDB::Status.build_by(twitter_user: self, status: tweet).slice(:uid, :screen_name, :raw_attrs_text)
  end
end
