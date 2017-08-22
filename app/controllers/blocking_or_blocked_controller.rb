class BlockingOrBlockedController < UnfriendsAndUnfollowers
  include TweetTextHelper
  include WorkersHelper

  def show
    super
    @disabled_label = 2
    render template: 'unfriends/show'
  end
end
