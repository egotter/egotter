class CloseFriendsController < ::Page::GoodFriends
  include CloseFriendsHelper

  def show
    super
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
