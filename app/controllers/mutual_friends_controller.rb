class MutualFriendsController < ApplicationController
  include SearchRequestConcern
  include DownloadRequestConcern

  def show
    @active_tab = 2
    render template: 'result_pages/show' unless performed?
  end

  def download
    data = data_for_download(@twitter_user.mutual_friends(limit: limit_for_download))
    render_for_download(data)
  end
end
