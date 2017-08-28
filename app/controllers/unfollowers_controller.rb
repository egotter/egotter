class UnfollowersController < UnfriendsAndUnfollowers
  include TweetTextHelper
  include WorkersHelper

  def show
    super
    @active_tab = 1
    render template: 'unfriends/show'
  end
end
