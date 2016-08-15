require 'digest/md5'

module PageCachesHelper
  def delete_cache_token(value)
    Digest::MD5.hexdigest("#{value}-#{ENV['SEED']}").slice(0, 20)
  end

  def verity_delete_cache_token(hash, value)
    hash && (match = hash.match(/\A[0-9a-zA-Z]{20}\z/)) && match[0] == delete_cache_token(value)
  end

  def create_instance_variables_for_result_page(tu)
    tu = tu.decorate

    @menu_items = [
      tu.removing_menu,
      tu.removed_menu,
      tu.new_friends_menu,
      tu.new_followers_menu,
      tu.blocking_or_blocked_menu,
      tu.mutual_friends_menu,
      tu.one_sided_friends_menu,
      tu.one_sided_followers_menu,
      tu.replying_menu,
      tu.replied_menu,
      tu.favoriting_menu,
      tu.inactive_friends_menu,
      tu.inactive_followers_menu
    ]

    @menu_common_friends_and_followers = tu.common_friend_and_followers_menu
    @menu_close_friends = tu.close_friends_menu
    @menu_usage_stats = tu.usage_stats_menu
    @menu_clusters_belong_to = tu.clusters_belong_to_menu
    @menu_update_histories = tu.update_histories_menu

    nil
  end
end
