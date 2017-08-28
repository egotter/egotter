class BlockingOrBlockedController < UnfriendsAndUnfollowers
  include TweetTextHelper
  include WorkersHelper

  def show
    super
    @active_tab = 2
    render template: 'unfriends/show'
  end
end
