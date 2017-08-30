class BlockingOrBlockedController < UnfriendsAndUnfollowers
  include TweetTextHelper
  include WorkersHelper

  def all
    super
    render template: 'friends/all' unless performed?
  end

  def show
    super
    @active_tab = 2
    render template: 'unfriends/show' unless performed?
  end
end
