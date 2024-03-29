class OneSidedFriendsController < ApplicationController
  include SearchRequestCreation
  include DownloadRequestConcern

  def new
  end

  def show
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end

  def download
    data = data_for_download(@twitter_user.one_sided_friends(limit: limit_for_download))
    render_for_download(data)
  end
end
