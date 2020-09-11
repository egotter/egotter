class FollowersController < ApplicationController
  include SearchRequestConcern

  def show
    @active_tab = 1
    render template: 'result_pages/show' unless performed?
  end
end
