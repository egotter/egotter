class FavoriteFriendsController < ::Page::GoodFriends
  def show
    super
    @active_tab = 1
    render template: 'result_pages/show' unless performed?
  end
end
