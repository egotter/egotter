SitemapGenerator::Sitemap.default_host = 'https://egotter.com'

SitemapGenerator::Sitemap.create do
  options = {priority: 0.8}

  add one_sided_friends_top_path, options
  add unfriends_top_path, options
  # add relationships_top_path, options

  Rails.logger.silence do
    TwitterUser.pluck(:uid).uniq.each do |uid|
      twitter_user = TwitterUser.latest(uid)
      next if twitter_user.protected_account?

      options = {priority: 0.5, changefreq: 'weekly', lastmod: twitter_user.updated_at}

      screen_name = twitter_user.screen_name
      add search_path(screen_name: screen_name), options
      add status_path(uid: uid), options
      add one_sided_friend_path(screen_name: screen_name, type: 'one_sided_friends'), options
      add one_sided_friend_path(screen_name: screen_name, type: 'one_sided_followers'), options
      add one_sided_friend_path(screen_name: screen_name, type: 'mutual_friends'), options
      add unfriend_path(screen_name: screen_name, type: 'removing'), options
      add unfriend_path(screen_name: screen_name, type: 'removed'), options
      add unfriend_path(screen_name: screen_name, type: 'blocking_or_blocked'), options

      %i(
        friends
        followers
        new_friends
        new_followers
        replying
        replied
        favoriting
        inactive_friends
        inactive_followers
        clusters_belong_to
        close_friends
        usage_stats
      ).each { |menu| add send("#{menu}_search_path", screen_name: screen_name), options }

    end

    options = {priority: 0.3}

    add support_path, options
    add terms_of_service_path, options
    add privacy_policy_path, options
  end
end
