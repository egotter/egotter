class Search
  MENU = %i(
    friends
    followers
    removing
    removed
    new_friends
    new_followers
    blocking_or_blocked
    one_sided_friends
    one_sided_followers
    mutual_friends
    common_friends
    common_followers
    replying
    replied
    favoriting
    inactive_friends
    inactive_followers
    clusters_belong_to
    close_friends
    usage_stats
  )

  # TODO remove new_friends and new_followers later
  API_V1_NAMES = %i(
    new_friends
    new_followers
    friends
    followers
    close_friends
    unfriends
    unfollowers
    blocking_or_blocked
    mutual_friends
    one_sided_friends
    one_sided_followers
    replying
    replied
    favoriting
    inactive_friends
    inactive_followers
  )
end
