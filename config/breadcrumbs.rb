crumb :root do
  link t('searches.common.top'), root_path
end

crumb :timeline do |screen_name|
  link t('timelines.show.short_title', user: mention_name(screen_name)), timeline_path(screen_name: screen_name)
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
    link t("#{name}.show.crumb_title"), send("#{name.singularize}_path", screen_name: screen_name)
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
    link t("#{name}.all.crumb_title"), send("all_#{name}_path", screen_name: screen_name)
    parent "#{name.singularize}".to_sym, screen_name
  end
end

crumb :relationship do |src_screen_name, dst_screen_name|
  link t('relationships.new.simple_title'), relationship_path(src_screen_name: src_screen_name, dst_screen_name: dst_screen_name)
  parent :timeline, src_screen_name
end

crumb :conversation do |screen_name|
  link t('conversations.new.simple_title'), conversation_path(screen_name: screen_name)
  parent :timeline, screen_name
end

crumb :cluster do |screen_name|
  link t('clusters.new.simple_title'), cluster_path(screen_name: screen_name)
  parent :timeline, screen_name
end
