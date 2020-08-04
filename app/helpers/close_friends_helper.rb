module CloseFriendsHelper
  def friend_map_edges_and_nodes(twitter_user)
    uids = twitter_user.close_friendships.limit(20).pluck(:friend_uid) << twitter_user.uid
    users = TwitterDB::User.where_and_order_by_field(uids: uids)

    edges = users.map do |user|
      [twitter_user.screen_name, user.screen_name]
    end

    nodes = users.map do |user|
      {
          id: user.screen_name,
          marker: {symbol: "url(#{user.profile_image_url_https})"}
      }
    end

    [edges, nodes]
  end
end
