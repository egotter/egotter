class AccessConfirmationsController < ApplicationController

  before_action :check_access_history, only: :index

  def index
    if user_signed_in?
      @user = TwitterDB::User.find_by(uid: current_user.uid)
      @user = TwitterUser.latest_by(uid: current_user.uid) unless @user
    end
  end

  def success
    @recipient_name = decrypted_recipient_name || 'user'
    if @recipient_name != 'user'
      @user = TwitterDB::User.find_by(screen_name: @recipient_name)
      @user = TwitterUser.latest_by(screen_name: @recipient_name) unless @user
    end
  end

  private

  def check_access_history
    if access_history_confirmed?
      redirect_to access_confirmations_success_path(recipient_name: params[:recipient_name], via: current_via)
    end
  end

  def access_history_confirmed?
    params[:recipient_name] &&
        (user = User.find_by(screen_name: decrypted_recipient_name)) &&
        !PeriodicReport.access_interval_too_long?(user)
  end

  def decrypted_recipient_name
    MessageEncryptor.new.decrypt(params[:recipient_name])
  rescue
    nil
  end
end
