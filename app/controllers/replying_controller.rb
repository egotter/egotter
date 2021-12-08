# TODO Rename to ReplyingFriendsController
class ReplyingController < ApplicationController
  include SearchRequestCreation

  def show
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
