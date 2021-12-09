class WaitingController < ApplicationController
  include SanitizationConcern

  before_action :reject_crawler
  before_action :reject_spam_access!
  before_action do
    # TODO This is a temporary workaround. Only :screen_name is accepted in the future.
    if params[:uid] && Validations::UidValidator::REGEXP.match?(params[:uid])
      uid = params[:uid].to_i
      request = SearchRequest.request_for(current_user&.id, uid: uid)
      screen_name = request&.screen_name
    elsif params[:screen_name] && Validations::ScreenNameValidator::REGEXP.match?(params[:screen_name])
      screen_name = params[:screen_name]
      request = SearchRequest.request_for(current_user&.id, screen_name: screen_name)
      uid = request&.uid
    else
      uid = screen_name = nil
    end

    if uid && screen_name
      @uid = uid
      @screen_name = screen_name
    else
      redirect_to root_path(via: 'invalid_uid_or_screen_name')
    end
  end
  before_action do
    set_user(@uid)
    set_redirect_path(@screen_name)
  end

  def index
  end

  private

  def set_user(uid)
    user = TwitterDB::User.find_by(uid: uid)
    user = TwitterUser.latest_by(uid: uid) unless user
    @user = user
  end

  def set_redirect_path(screen_name)
    if params[:redirect_path]
      path = sanitized_redirect_path(params[:redirect_path])
      path.sub!(':screen_name', screen_name) if path.include?(':screen_name')
    else
      path = timeline_path(screen_name: screen_name, via: current_via('waiting_redirect'))
    end
    @redirect_path = path
  end
end
