class FriendsController < ApplicationController
  include SearchRequestCreation
  include DownloadRequestConcern

  def new
  end

  def show
    @active_tab = 0
    render template: 'result_pages/show' unless performed?
  end

  def download
    @twitter_user = TwitterUser.with_delay.latest_by(uid: @twitter_user.uid) # Avoid calling #friend_uids
    data = data_for_download(@twitter_user.friends(limit: limit_for_download))
    render_for_download(data)
  end
end
