class BlockingOrBlockedController < ::Base
  include TweetTextHelper

  def show
    super

    counts = {
      unfriends: @twitter_user.unfriendships.size,
      unfollowers: @twitter_user.unfollowerships.size,
      blocking_or_blocked: @twitter_user.blocking_or_blocked_uids.size
    }

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name}.merge(counts))

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name}.merge(counts))

    mention_names = @twitter_user.unfriends.select(:screen_name).limit(3).map(&:mention_name)
    names = '.' + honorific_names(mention_names)
    @tweet_text = t('.tweet_text', users: names, url: @canonical_url)
  end
end
