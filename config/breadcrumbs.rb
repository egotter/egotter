crumb :root do
  link t('searches.common.top'), root_path
end

crumb :search do |screen_name|
  link t('searches.show.simple_title', user: mention_name(screen_name)), search_path(screen_name: screen_name)
  parent :root
end

crumb :status do |uid, screen_name|
  link t('searches.common.tweet'), status_path(uid: uid)
  parent :search, screen_name
end

crumb :common do |screen_name, menu|
  link t("searches.#{menu}.name"), send("#{menu}_search_path", screen_name: screen_name)
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