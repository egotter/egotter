class FavoriteFriendsController < GoodFriends
  def all
    super
    render template: 'friends/all'
  end

  def show
    super
    render template: 'close_friends/show'
  end
end
