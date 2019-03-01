class AudienceInsightChartBuilder
  def initialize(uid, limit: 10)
    @twitter_users = TwitterUser.where(uid: uid).order(created_at: :desc).limit(limit).reverse
    S3::Profile.where(twitter_user_ids: @twitter_users.map(&:id))
    @statuses = TwitterDB::User.new(uid: uid).statuses
  end

  DATE_FORMAT = "%Y-%m-%d"

  def categories
    @twitter_users.map(&:created_at).map {|t| t.strftime(DATE_FORMAT)}
  end

  def friends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.friends'), data: @twitter_users.map(&:friends_count)}
  end

  def followers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.followers'), data: @twitter_users.map(&:followers_count)}
  end

  def new_friends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_friends'), data: @twitter_users.map {|user| user.calc_new_friend_uids.size}}
  end

  def new_followers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_followers'), data: @twitter_users.map {|user| user.calc_new_follower_uids.size}}
  end

  def unfriends
    # {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.unfriends'), data: @twitter_users.map {|user| user.calc_unfriend_uids.size}}
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.unfriends'), data: []}
  end

  def unfollowers
    # {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.unfollowers'), data: @twitter_users.map {|user| user.calc_unfollower_uids.size}}
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.unfollowers'), data: []}
  end

  def new_unfriends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_unfriends'), data: @twitter_users.map {|user| user.calc_new_unfriend_uids.size}}
  end

  def new_unfollowers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_unfollowers'), data: @twitter_users.map {|user| user.calc_new_unfollower_uids.size}}
  end

  def tweets_categories
    @statuses.map(&:tweeted_at).map {|t| t.strftime(DATE_FORMAT)}.uniq.reverse
  end

  def tweets
    dates = @statuses.map {|status| status.tweeted_at.strftime(DATE_FORMAT)}
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.tweets'), data: tweets_categories.map {|category| dates.select {|d| d == category}.size}}
  end

  def replies

  end
end
