class BlockingOrBlockedController < ::Page::Base
  include Concerns::UnfriendsConcern
  include TweetTextHelper

  def all
    initialize_instance_variables
    @collection = @twitter_user.block_friends.limit(300)
    render template: 'friends/all' unless performed?
  end

  def show
    initialize_instance_variables
    @active_tab = 2
    render template: 'unfriends/show' unless performed?
  end
end
