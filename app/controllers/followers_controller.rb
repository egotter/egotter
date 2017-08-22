class FollowersController < ::Base
  def show
    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", screen_name: @twitter_user.screen_name)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    counts = {
      followers: @twitter_user.followerships.size,
      one_sided_followers: @twitter_user.one_sided_followerships.size,
      one_sided_followers_rate: (@twitter_user.one_sided_followers_rate * 100).round(1)
    }

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name}.merge(counts))

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name}.merge(counts))

    @tweet_text = t('.tweet_text', {user: @twitter_user.mention_name, url: @canonical_url}.merge(counts))

    @stat = UsageStat.find_by(uid: @twitter_user.uid)
  end
end
