SitemapGenerator::Sitemap.default_host = 'https://egotter.com'

uids = TwitterUser.pluck(:uid).uniq
puts "uids: #{uids.size}"

do_create = Proc.new do
  options = {priority: 0.8}

  with_options options do |obj|
    obj.add one_sided_friends_top_path
    obj.add unfriends_top_path
    obj.add inactive_friends_top_path
    obj.add friends_top_path
    obj.add clusters_top_path
  end

  uids.each do |uid|
    twitter_user = TwitterUser.select(:screen_name, :user_info, :updated_at).latest_by(uid: uid)
    next if twitter_user.protected_account? || twitter_user.suspended_account?

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

  with_options options do |obj|
    obj.add support_path
    obj.add terms_of_service_path
    obj.add privacy_policy_path
  end

  add directory_path, options
  100.times do |n|
    add directory_path(id1: n), options
    10.times do |nn|
      add directory_path(id1: n, id2: nn), options
    end
  end
end

SitemapGenerator::Sitemap.create { Rails.logger.silence(&do_create) }
