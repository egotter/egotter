class CloseFriendsController < ApplicationController
  include Concerns::SearchRequestConcern

  def show
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
