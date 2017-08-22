class UnfollowersController < UnfriendsAndUnfollowers
  include TweetTextHelper
  include WorkersHelper

  def show
    super
    @disabled_label = 1
    render template: 'unfriends/show'
  end
end
