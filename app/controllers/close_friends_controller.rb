class CloseFriendsController < GoodFriends
  include CloseFriendsHelper

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
  end
end
