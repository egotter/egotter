class WaitingController < ApplicationController
  include SanitizationConcern

  before_action :reject_crawler
  before_action :reject_spam_access!
  before_action { valid_uid?(params[:uid]) }
  before_action { @twitter_user = build_twitter_user_by_uid(params[:uid]) }

  def new
    @redirect_path = sanitized_redirect_path(params[:redirect_path].presence || timeline_path(@twitter_user, via: current_via('waiting_redirect')))
    @redirect_path.sub!(':screen_name', @twitter_user.screen_name) if @redirect_path.include?(':screen_name')
    @jid = params[:jid]
  end
end
