class WaitingController < ApplicationController
  include Concerns::SanitizationConcern

  before_action :reject_crawler
  before_action { valid_uid?(params[:uid]) }
  before_action { searched_uid?(params[:uid]) }
  before_action { @twitter_user = build_twitter_user_by_uid(params[:uid]) }

  before_action do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session.delete(:sign_in_from))
    elsif session[:sign_out_from].present?
      create_search_log(referer: session.delete(:sign_out_from))
    else
      create_search_log
    end
  end

  def new
    @redirect_path = sanitized_redirect_path(params[:redirect_path].presence || timeline_path(twitter_user))
    @twitter_user = twitter_user
    @jid = params[:jid]
  end
end
