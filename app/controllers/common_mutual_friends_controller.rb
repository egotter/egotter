class CommonMutualFriendsController < ::Page::CommonFriendsAndCommonFollowers

  def show
    super
    @active_tab = 2
    render template: 'result_pages/show' unless performed?
  end
end
