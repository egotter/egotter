SitemapGenerator::Sitemap.default_host = 'https://egotter.com'

SitemapGenerator::Sitemap.create do
  add one_sided_friends_top_path, priority: 0.8, changefreq: 'daily'
  add unfriends_top_path, priority: 0.8, changefreq: 'daily'

  processed = []
  Rails.logger.silence do
    TwitterUser.with_friends.find_in_batches(start: 1, batch_size: 1000) do |tu_array|
      uids = tu_array.select { |tu| processed.exclude?(tu.uid.to_i) }.map(&:uid).uniq

      uids.each do |uid|
        twitter_user = TwitterUser.order(created_at: :desc).find_by(uid: uid)
        if twitter_user.protected_account?
          processed << uid.to_i
          next
        end

        screen_name = twitter_user.screen_name
        add search_path(screen_name: screen_name), changefreq: 'daily'
        add status_path(uid: uid), changefreq: 'daily'
        add one_sided_friend_path(screen_name: screen_name, type: 'one_sided_friends'), changefreq: 'daily'
        add one_sided_friend_path(screen_name: screen_name, type: 'one_sided_followers'), changefreq: 'daily'
        add one_sided_friend_path(screen_name: screen_name, type: 'mutual_friends'), changefreq: 'daily'
        add unfriend_path(screen_name: screen_name, type: 'removing'), changefreq: 'daily'
        add unfriend_path(screen_name: screen_name, type: 'removed'), changefreq: 'daily'
        add unfriend_path(screen_name: screen_name, type: 'blocking_or_blocked'), changefreq: 'daily'

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
        ).each { |menu| add send("#{menu}_search_path", screen_name: screen_name), changefreq: 'daily' }

        add support_path
        add terms_of_service_path
        add privacy_policy_path

        processed << uid.to_i
      end
    end
  end
end
