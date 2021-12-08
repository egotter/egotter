class CloseFriendsController < ApplicationController
  include SearchRequestCreation

  def new
  end

  def show
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
