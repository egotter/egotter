SitemapGenerator::Sitemap.default_host = 'https://egotter.com'

uids = TwitterUser.pluck(:uid).uniq
puts "uids: #{uids.size}"

do_create = Proc.new do
  options = {priority: 0.8}

  add one_sided_friends_top_path, options
  add unfriends_top_path, options
  add inactive_friends_top_path, options
  add friends_top_path, options
  add clusters_top_path, options

  uids.each do |uid|
    twitter_user = TwitterUser.select(:screen_name, :user_info, :updated_at).latest(uid)
    next if twitter_user.protected_account?

    options = {priority: 0.5, changefreq: 'weekly', lastmod: twitter_user.updated_at}

    with_options options do |obj|
      obj.add timeline_path twitter_user
      obj.add one_sided_friend_path twitter_user
      obj.add one_sided_follower_path twitter_user
      obj.add mutual_friend_path twitter_user
      obj.add unfriend_path twitter_user
      obj.add unfollower_path twitter_user
      obj.add blocking_or_blocked_path twitter_user
      obj.add inactive_friend_path twitter_user
      obj.add inactive_follower_path twitter_user
      obj.add inactive_mutual_friend_path twitter_user
      obj.add friend_path twitter_user
      obj.add follower_path twitter_user
      obj.add status_path twitter_user
      obj.add replying_path twitter_user
      obj.add replied_path twitter_user
      obj.add replying_and_replied_path twitter_user
      obj.add cluster_path twitter_user
      obj.add close_friend_path twitter_user
      obj.add favorite_friend_path twitter_user
      obj.add usage_stat_path twitter_user
    end
  end

  options = {priority: 0.3}

  add support_path, options
  add terms_of_service_path, options
  add privacy_policy_path, options
end

SitemapGenerator::Sitemap.create { Rails.logger.silence(&do_create) }
