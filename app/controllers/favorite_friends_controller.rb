class FavoriteFriendsController < GoodFriends
  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    render template: 'close_friends/show' unless performed?
  end
end
