class ReplyingAndRepliedController < ApplicationController
  include Concerns::SearchRequestConcern

  def show
    @active_tab = 2
    render template: 'result_pages/show' unless performed?
  end
end
