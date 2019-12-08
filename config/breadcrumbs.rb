crumb :root do
  link t('searches.common.top'), root_path(via: build_via('breadcrumb_root'))
end

crumb :start do |screen_name|
  link t('home.start.crumb_title', user: screen_name), profile_path(screen_name: screen_name, via: build_via("breadcrumb_start"))
  parent :root
end

crumb :timeline do |screen_name|
  link t('timelines.show.short_title', user: mention_name(screen_name)), timeline_path(screen_name: screen_name, via: build_via('breadcrumb_timeline'))
  parent :root
end

%w(
  friends
  followers
  statuses
  audience_insights
  close_friends
  favorite_friends
  scores
  usage_stats
  unfriends
  unfollowers
  blocking_or_blocked
  inactive_friends
  inactive_followers
  inactive_mutual_friends
  one_sided_friends
  one_sided_followers
  mutual_friends
  replying
  replied
  replying_and_replied
  common_friends
  common_followers
  common_mutual_friends
).each do |name|
  crumb name.singularize.to_sym do |screen_name|
    link t("#{name}.show.crumb_title"), send("#{name.singularize}_path", screen_name: screen_name, via: build_via("breadcrumb_#{name}"))
    parent :timeline, screen_name
  end
end

%w(
  friends
  followers
  close_friends
  favorite_friends
  inactive_friends
  inactive_followers
  inactive_mutual_friends
  one_sided_friends
  one_sided_followers
  mutual_friends
  replying
  replied
  replying_and_replied
  common_friends
  common_followers
  common_mutual_friends
).each do |name|
  crumb "all_#{name}".to_sym do |screen_name|
    link t("#{name}.all.crumb_title"), send("all_#{name}_path", screen_name: screen_name, via: build_via("breadcrumb_#{name}"))
    parent "#{name.singularize}".to_sym, screen_name
  end
end

crumb :profile do |screen_name, time|
  link t('profiles.show.crumb_title', user: screen_name, time: time), profile_path(screen_name: screen_name, via: build_via("breadcrumb_profile"))
  parent :root
end

crumb :latest_profile do |screen_name|
  link t('profiles.latest.crumb_title', user: screen_name), latest_profile_path(screen_name: screen_name, via: build_via("breadcrumb_latest_profile"))
  parent :root
end

crumb :relationship do |src_screen_name, dst_screen_name|
  link t('relationships.new.simple_title'), relationship_path(src_screen_name: src_screen_name, dst_screen_name: dst_screen_name, via: build_via("breadcrumb_relationship"))
  parent :timeline, src_screen_name
end

crumb :conversation do |screen_name|
  link t('conversations.new.simple_title'), conversation_path(screen_name: screen_name, via: build_via("breadcrumb_conversation"))
  parent :timeline, screen_name
end

crumb :cluster do |screen_name|
  link t('clusters.new.crumb_title'), cluster_path(screen_name: screen_name, via: build_via("breadcrumb_cluster"))
  parent :timeline, screen_name
end
