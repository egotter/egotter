class TwitterUserSnapshot
  attr_accessor(
      :uid,
      :screen_name,
      :friends_count,
      :followers_count,
      :profile,
      :friends_size,
      :followers_size,
      :friend_uids,
      :follower_uids
  )

  def [](key)
    if key == :friends_count
      friends_count
    elsif key == :followers_count
      followers_count
    else
      raise "Invalid key #{key}"
    end
  end

  def initialize(uid:, screen_name:, friends_count:, followers_count:, user:)
    @uid = uid
    @screen_name = screen_name
    @friends_count = friends_count
    @followers_count = followers_count
    @user = user
  end

  def build_by(resources)
    build_statuses(resources[:user_timeline]).
        build_favorites(resources[:favorites]).
        build_mentions(resources[:mentions_timeline], resources[:search])
  end

  def build_friends(friend_ids)
    self.friends_size = 0

    if friend_ids&.any?
      self.friend_uids = friend_ids
      self.friends_size = friend_ids.size
    else
      self.friend_uids = []
      self.friends_size = 0
    end
  end

  def build_followers(follower_ids)
    self.followers_size = 0

    if follower_ids&.any?
      self.follower_uids = follower_ids
      self.followers_size = follower_ids.size
    else
      self.follower_uids = []
      self.followers_size = 0
    end
  end

  # It takes a few seconds if the relation has thousands of objects.
  def build_statuses(user_timeline)
    if user_timeline&.any?
      user_timeline.each { |status| Status.build(TwitterDB::Status.attrs_by(twitter_user: self, status: status)) }
    end

    self
  end

  # It takes a few seconds if the relation has thousands of objects.
  def build_favorites(favorites)
    if favorites&.any?
      favorites.each { |status| Favorite.build(TwitterDB::Favorite.attrs_by(twitter_user: self, status: status)) }
    end

    self
  end

  # It takes a few seconds if the relation has thousands of objects.
  def build_mentions(mentions_timeline, searched_tweets)
    if (mentions_timeline.nil? || mentions_timeline.empty?) && (!searched_tweets.nil? && !searched_tweets.empty?)
      mentions_timeline = reject_your_own_tweets(searched_tweets)
    end

    if mentions_timeline&.any?
      mentions_timeline.each { |status| Mention.build(TwitterDB::Mention.attrs_by(twitter_user: self, status: status)) }
    end

    self
  end

  def twitter_user

  end

  def reject_your_own_tweets(tweets)
    tweets.reject { |status| @uid == status[:user][:id] || status[:text].start_with?("RT @#{@screen_name}") }
  end

  class << self
    def initialize_by(user:)
      new(
          uid: user[:id],
          screen_name: user[:screen_name],
          friends_count: user[:friends_count],
          followers_count: user[:followers_count],
          user: user
      )
    end
  end
end
