class CloseFriendsController < ::Page::GoodFriends
  include CloseFriendsHelper

  def all
    super
    render template: 'result_pages/all' unless performed?
  end

  def show
    super
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
