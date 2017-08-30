SitemapGenerator::Sitemap.default_host = 'https://egotter.com'

uids = TwitterUser.pluck(:uid).uniq
puts "uids: #{uids.size}"

do_create = Proc.new do
  options = {priority: 0.8}

  add one_sided_friends_top_path, options
  add unfriends_top_path, options
  add relationships_top_path, options
  add inactive_friends_top_path, options
  add friends_top_path, options
  add conversations_top_path, options
  add clusters_top_path, options

  uids.each do |uid|
    twitter_user = TwitterUser.latest(uid)
    next if twitter_user.protected_account?

    options = {priority: 0.5, changefreq: 'weekly', lastmod: twitter_user.updated_at}

    screen_name = twitter_user.screen_name
    add timeline_path(twitter_user), options
    add one_sided_friend_path(twitter_user, type: 'one_sided_friends'), options
    add one_sided_friend_path(twitter_user, type: 'one_sided_followers'), options
    add one_sided_friend_path(twitter_user, type: 'mutual_friends'), options
    add unfriend_path(twitter_user), options
    add unfollower_path(twitter_user), options
    add blocking_or_blocked_path(twitter_user), options
    add inactive_friend_path(twitter_user, type: 'inactive_friends'), options
    add inactive_friend_path(twitter_user, type: 'inactive_followers'), options
    add inactive_friend_path(twitter_user, type: 'inactive_mutual_friends'), options
    add friend_path(twitter_user), options
    add follower_path(twitter_user), options
    add status_path(twitter_user), options
    add conversation_path(twitter_user, type: 'replying'), options
    add conversation_path(twitter_user, type: 'replied'), options
    add conversation_path(twitter_user, type: 'replying_and_replied'), options
    add cluster_path(twitter_user), options
    add close_friend_path(twitter_user), options
    add favorite_friend_path(twitter_user), options
    add usage_stat_path(twitter_user), options

    twitter_user.close_friends.take(3).each do |close_friend|
      add relationship_path(src_screen_name: screen_name, dst_screen_name: close_friend.screen_name, type: 'conversations'), options
      add relationship_path(src_screen_name: screen_name, dst_screen_name: close_friend.screen_name, type: 'common_friends'), options
      add relationship_path(src_screen_name: screen_name, dst_screen_name: close_friend.screen_name, type: 'common_followers'), options
    end
  end

  options = {priority: 0.3}

  add support_path, options
  add terms_of_service_path, options
  add privacy_policy_path, options
end

SitemapGenerator::Sitemap.create { Rails.logger.silence(&do_create) }
