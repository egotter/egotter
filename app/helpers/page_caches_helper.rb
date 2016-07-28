require 'digest/md5'

module PageCachesHelper
  def delete_cache_token(value)
    Digest::MD5.hexdigest("#{value}-#{ENV['SEED']}").slice(0, 20)
  end

  def create_instance_variables_for_result_page(tu)
    @menu_items = [
      removing_menu(tu),
      removed_menu(tu),
      blocking_or_blocked_menu(tu),
      mutual_friends_menu(tu),
      one_sided_friends_menu(tu),
      one_sided_followers_menu(tu),
      replying_menu(tu),
      replied_menu(tu),
      favoriting_menu(tu),
      inactive_friends_menu(tu),
      inactive_followers_menu(tu)
    ]

    @menu_common_friends_and_followers = common_friend_and_followers_menu(tu)
    @menu_close_friends = close_friends_menu(tu)
    @menu_usage_stats = usage_stats_menu(tu)
    @menu_clusters_belong_to = clusters_belong_to_menu(tu)
    @menu_update_histories = update_histories_menu(tu)

    @searched_tw_user = tu
  end
end
