class UnfollowersController < ::Page::Base
  include Concerns::UnfriendsConcern
  include TweetTextHelper

  def all
    initialize_instance_variables
    @collection = @twitter_user.unfollowers.limit(300)
    render template: 'friends/all' unless performed?
  end

  def show
    initialize_instance_variables
    @active_tab = 1
    render template: 'unfriends/show' unless performed?
  end
end
