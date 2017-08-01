module CloseFriendsHelper
  def friend_map_users
    uids = @twitter_user.close_friendships.limit(20).pluck(:friend_uid) << @twitter_user.uid.to_i
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    uids.map { |uid| users[uid] }.compact
  end

  def user2node(user)
    {id: user.screen_name, url: normal_icon_url(user)}
  end

  def user2link(source_user, target_user)
    {source: source_user.screen_name, target: target_user.screen_name, value: 1, group: 0}
  end
end
