class FriendsController < ApplicationController
  include SearchRequestConcern
  include DownloadRequestConcern

  def new
  end

  def show
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end

  def download
    @twitter_user = TwitterUser.with_delay.latest_by(uid: @twitter_user.uid)
    data = data_for_download(@twitter_user.friends(limit: limit_for_download))
    send_data data, filename: filename_for_download(@twitter_user), type: 'text/csv; charset=utf-8'
  end
end
