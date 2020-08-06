class ReplyingController < ::Page::Base
  include Concerns::FriendsConcern

  def show
    initialize_instance_variables
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end
end
