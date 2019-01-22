class UnfollowersController < UnfriendsAndUnfollowers
  include TweetTextHelper

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 1
    render template: 'unfriends/show' unless performed?
  end
end
