class CommonMutualFriendsController < ::Page::CommonFriendsAndCommonFollowers

  def all
    super
    render template: 'result_pages/all' unless performed?
  end

  def show
    super
    @active_tab = 2
    render template: 'result_pages/show' unless performed?
  end
end
