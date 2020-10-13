class FollowersController < ApplicationController
  include SearchRequestConcern
  include DownloadRequestConcern

  def show
    @active_tab = 1
    render template: 'result_pages/show' unless performed?
  end

  def download
    @twitter_user = TwitterUser.with_delay.latest_by(uid: @twitter_user.uid) # Avoid calling #follower_uids
    data = data_for_download(@twitter_user.followers(limit: limit_for_download))
    send_data data, filename: filename_for_download(@twitter_user), type: 'text/csv; charset=utf-8'
  end
end
