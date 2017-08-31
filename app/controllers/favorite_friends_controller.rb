class FavoriteFriendsController < GoodFriends
  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 1
    render template: 'close_friends/show' unless performed?
  end
end
