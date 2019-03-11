class CloseFriendsController < ::Page::GoodFriends
  include CloseFriendsHelper

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    @active_tab = 0
    super
  end
end
