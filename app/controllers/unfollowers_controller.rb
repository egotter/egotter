class UnfollowersController < ::Page::Base
  include Concerns::UnfriendsConcern
  include TweetTextHelper

  def show
    initialize_instance_variables
    @active_tab = 1
    render template: 'result_pages/show' unless performed?
  end
end
