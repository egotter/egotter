crumb :root do
  link t('searches.common.top'), root_path
end

crumb :search do |screen_name|
  link t('searches.show.simple_title', user: mention_name(screen_name)), search_path(screen_name: screen_name)
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

crumb :close_friend do |screen_name|
  link t('close_friends.show.title'), close_friend_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :score do |screen_name|
  link t('scores.show.title'), score_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :one_sided_friend do |screen_name|
  link t('one_sided_friends.new.simple_title'), one_sided_friend_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :unfriend do |screen_name|
  link t('unfriends.new.simple_title'), unfriend_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :relationship do |src_screen_name, dst_screen_name|
  link t('relationships.new.simple_title'), relationship_path(src_screen_name: src_screen_name, dst_screen_name: dst_screen_name)
  parent :search, src_screen_name
end

crumb :inactive_friend do |screen_name|
  link t('inactive_friends.new.simple_title'), inactive_friend_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :friend do |screen_name|
  link t('friends.new.simple_title'), friend_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :conversation do |screen_name|
  link t('conversations.new.simple_title'), conversation_path(screen_name: screen_name)
  parent :search, screen_name
end

crumb :cluster do |screen_name|
  link t('clusters.new.simple_title'), cluster_path(screen_name: screen_name)
  parent :search, screen_name
end
