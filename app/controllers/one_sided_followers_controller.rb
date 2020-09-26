class OneSidedFollowersController < ApplicationController
  include SearchRequestConcern
  include DownloadRequestConcern

  def show
    @active_tab = 1
    render template: 'result_pages/show' unless performed?
  end

  def download
    data = data_for_download(@twitter_user.one_sided_followers(limit: limit_for_download))
    send_data data, filename: filename_for_download(@twitter_user), type: 'text/csv; charset=utf-8'
  end
end
