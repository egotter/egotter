SitemapGenerator::Sitemap.default_host = 'https://egotter.com'

SitemapGenerator::Sitemap.create do
  options = {priority: 0.8}

  add one_sided_friends_top_path, options
  add unfriends_top_path, options
  add relationships_top_path, options
  add inactive_friends_top_path, options
  add friends_top_path, options

  Rails.logger.silence do
    TwitterUser.pluck(:uid).uniq.each do |uid|
      twitter_user = TwitterUser.latest(uid)
      next if twitter_user.protected_account?

      options = {priority: 0.5, changefreq: 'weekly', lastmod: twitter_user.updated_at}

      screen_name = twitter_user.screen_name
      add search_path(screen_name: screen_name), options
      add one_sided_friend_path(screen_name: screen_name, type: 'one_sided_friends'), options
      add one_sided_friend_path(screen_name: screen_name, type: 'one_sided_followers'), options
      add one_sided_friend_path(screen_name: screen_name, type: 'mutual_friends'), options
      add unfriend_path(screen_name: screen_name, type: 'removing'), options
      add unfriend_path(screen_name: screen_name, type: 'removed'), options
      add unfriend_path(screen_name: screen_name, type: 'blocking_or_blocked'), options
      add inactive_friend_path(screen_name: screen_name, type: 'inactive_friends'), options
      add inactive_friend_path(screen_name: screen_name, type: 'inactive_followers'), options
      add inactive_friend_path(screen_name: screen_name, type: 'inactive_mutual_friends'), options
      add friend_path(screen_name: screen_name, type: 'friends'), options
      add friend_path(screen_name: screen_name, type: 'followers'), options
      add friend_path(screen_name: screen_name, type: 'statuses'), options

      TwitterDB::User.where(uid: twitter_user.close_friend_uids.take(3)).each do |close_friend|
        add relationship_path(src_screen_name: screen_name, dst_screen_name: close_friend.screen_name, type: 'conversations'), options
        add relationship_path(src_screen_name: screen_name, dst_screen_name: close_friend.screen_name, type: 'common_friends'), options
        add relationship_path(src_screen_name: screen_name, dst_screen_name: close_friend.screen_name, type: 'common_followers'), options
      end

      %i(
        new_friends
        new_followers
        replying
        replied
        favoriting
        clusters_belong_to
        close_friends
        usage_stats
      ).each { |menu| add search_path_for(menu, screen_name), options }

    end

    options = {priority: 0.3}

    add support_path, options
    add terms_of_service_path, options
    add privacy_policy_path, options
  end
end
