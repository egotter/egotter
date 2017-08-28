crumb :root do
  link t('searches.common.top'), root_path
end

crumb :search do |screen_name|
  link t('searches.show.simple_title', user: mention_name(screen_name)), timeline_path(screen_name: screen_name)
  parent :root
end

crumb :timeline do |screen_name|
  link t('timelines.show.short_title', user: mention_name(screen_name)), timeline_path(screen_name: screen_name)
  parent :root
end

crumb :common do |screen_name, menu|
  link t("searches.#{menu}.name"), search_path_for(menu, screen_name)
  parent :search, screen_name
end

%w(
  friends
  followers
  statuses
  close_friends
  favorite_friends
  scores
  usage_stats
  unfriends
  unfollowers
  blocking_or_blocked
  inactive_friends
  inactive_followers
  one_sided_friends
  one_sided_followers
  mutual_friends
).each do |name|
  crumb name.singularize.to_sym do |screen_name|
    link t("#{name}.show.crumb_title"), send("#{name.singularize}_path", screen_name: screen_name)
    parent :search, screen_name
  end
end

%w(
  friends
  followers
  close_friends
  favorite_friends
  inactive_friends
  inactive_followers
  one_sided_friends
  one_sided_followers
  mutual_friends
).each do |name|
  crumb "all_#{name}".to_sym do |screen_name|
    link t("#{name}.all.crumb_title"), send("all_#{name}_path", screen_name: screen_name)
    parent "#{name.singularize}".to_sym, screen_name
  end
end

crumb :relationship do |src_screen_name, dst_screen_name|
  link t('relationships.new.simple_title'), relationship_path(src_screen_name: src_screen_name, dst_screen_name: dst_screen_name)
  parent :search, src_screen_name
end

crumb :conversation do |screen_name|
  link t('conversations.new.simple_title'), conversation_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :cluster do |screen_name|
  link t('clusters.new.simple_title'), cluster_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :update_history do |screen_name|
  link t('update_histories.show.short_title'), update_history_path(screen_name: screen_name)
  parent :search, screen_name
end
