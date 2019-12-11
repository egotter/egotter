require 'active_support/concern'

module Concerns::UnfriendsConcern
  extend ActiveSupport::Concern

  included do

  end

  def initialize_instance_variables
    singular_name = controller_name.singularize

    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = singular_name.to_sym
    @canonical_url = send("#{singular_name}_url", @twitter_user)
    @canonical_path = send("#{singular_name}_path", @twitter_user)
    @page_title = t('.page_title', user: @twitter_user.screen_name)
    @content_title = t('.content_title', user: @twitter_user.screen_name)

    counts = related_counts(@twitter_user)
    @meta_title = t('.meta_title', {user: @twitter_user.screen_name}.merge(counts))

    @page_description = t('.page_description_html', user: user_link(@twitter_user.screen_name), url: unfriends_top_path(via: build_via('page_description')))
    @meta_description = t('.meta_description', {user: @twitter_user.screen_name}.merge(counts))

    mention_names = @twitter_user.users_by(controller_name: controller_name).
        select(:screen_name).limit(3).map(&:mention_name)

    if mention_names.empty?
      @tweet_text = t('unfriends.show.tweet_empty_text', url: unfriends_top_url(via: build_via('tweet_for_empty')))
    else
      names = '.' + mention_names.map { |name| honorific_name(name) }.join("\n") + "\n\n"

      @tweet_text = t('.tweet_text', users: names, url: unfriends_top_url(via: build_via('tweet_for_users')))
    end

    @tabs = tabs(counts)
  end

  def related_counts(twitter_user)
    values = {}

    Timeout.timeout(2.seconds) do
      values[:unfriends] = twitter_user.unfriendships.size
      values[:unfollowers] = twitter_user.unfollowerships.size
      values[:blocking_or_blocked] = twitter_user.block_friendships.size
    end

    values
  rescue Timeout::Error => e
    logger.warn "#{controller_name}##{__method__} #{e.class} #{e.message} #{current_user_id} #{twitter_user.id}"
    logger.info e.backtrace.join("\n")

    values[:unfriends] = -1 unless values.has_key?(:unfriends)
    values[:unfollowers] = -1 unless values.has_key?(:unfollowers)
    values[:blocking_or_blocked] = -1 unless values.has_key?(:blocking_or_blocked)

    values
  end

  def tabs(counts)
    [
        {text: t('unfriends.show.unfriends_tab_html', num: counts[:unfriends]), url: unfriend_path(@twitter_user, via: build_via('tab'))},
        {text: t('unfriends.show.unfollowers_tab_html', num: counts[:unfollowers]), url: unfollower_path(@twitter_user, via: build_via('tab'))},
        {text: t('unfriends.show.blocking_or_blocked_tab_html', num: counts[:blocking_or_blocked]), url: blocking_or_blocked_path(@twitter_user, via: build_via('tab'))}
    ]
  end
end
