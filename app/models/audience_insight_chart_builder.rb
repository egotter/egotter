class AudienceInsightChartBuilder
  def initialize(uid, limit: 10)
    @builder = FriendsGroupBuilder.new(uid, limit: limit)
    @statuses = TwitterUser.latest_by(uid: uid).status_tweets
  end

  DATE_FORMAT = "%Y-%m-%d"

  def categories
    @categories ||= @builder.users.map(&:created_at).map {|t| t.strftime(DATE_FORMAT)}
  end

  def friends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.friends'), data: @builder.friends.map(&:size)}
  end

  def followers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.followers'), data: @builder.followers.map(&:size)}
  end

  def new_friends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_friends'), data: @builder.new_friends.map(&:size)}
  end

  def new_followers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_followers'), data: @builder.new_followers.map(&:size)}
  end

  def unfriends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.unfriends'), data: @builder.unfriends.map(&:size)}
  end

  def unfollowers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.unfollowers'), data: @builder.unfollowers.map(&:size)}
  end

  def new_unfriends
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_unfriends'), data: []}
  end

  def new_unfollowers
    {name: I18n.t('activerecord.attributes.audience_insight_chart_builder.new_unfollowers'), data: []}
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
