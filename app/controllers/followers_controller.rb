class FollowersController < FriendsAndFollowers
  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    render template: 'friends/show' unless performed?
  end

  private

  def related_counts
    {
      followers: @twitter_user.followerships.size,
      one_sided_followers: @twitter_user.one_sided_followerships.size,
      one_sided_followers_rate: (@twitter_user.one_sided_followers_rate * 100).round(1)
    }
  end
end
