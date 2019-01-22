class UnfriendsAndUnfollowers < ApplicationController
  include Concerns::Showable
  include Concerns::Indexable

  def all
    unless user_signed_in?
      via = "#{controller_name}/#{action_name}/need_login"
      redirect = send("all_#{controller_name}_path", @twitter_user)
      return redirect_to sign_in_path(via: via, redirect_path: redirect)
    end
    initialize_instance_variables
    @collection = @twitter_user.twitter_db_user.send(controller_name)
  end

  def show
    initialize_instance_variables
  end

  private

  def initialize_instance_variables
    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)
    @canonical_path = send("#{controller_name.singularize}_path", @twitter_user)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    counts = related_counts(@twitter_user)
    @meta_title = t('.meta_title', {user: @twitter_user.mention_name}.merge(counts))

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name}.merge(counts))

    mention_names = @twitter_user.twitter_db_user.send(controller_name).select(:screen_name).limit(3).map(&:mention_name)
    names = '.' + honorific_names(mention_names)
    @tweet_text = t('.tweet_text', users: names, url: @canonical_url)

    @tabs = tabs(counts)
  end

  def related_counts(twitter_user)
    user = twitter_user.twitter_db_user
    {
      unfriends: user.unfriendships.size,
      unfollowers: user.unfollowerships.size,
      blocking_or_blocked: user.blocking_or_blocked_uids.size
    }
  end

  def tabs(counts)
    [
      {text: t('unfriends.show.see_unfriends_html', num: counts[:unfriends]), url: unfriend_path(@twitter_user)},
      {text: t('unfriends.show.see_unfollowers_html', num: counts[:unfollowers]), url: unfollower_path(@twitter_user)},
      {text: t('unfriends.show.see_blocking_or_blocked_html', num: counts[:blocking_or_blocked]), url: blocking_or_blocked_path(@twitter_user)}
    ]
  end
end