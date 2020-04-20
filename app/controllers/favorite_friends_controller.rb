class FavoriteFriendsController < ::Page::GoodFriends
  def all
    super
    render template: 'result_pages/all' unless performed?
  end

  def show
    super
    @active_tab = 1
    render template: 'result_pages/show' unless performed?
  end
end
