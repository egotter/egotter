class ProfilesController < ApplicationController
  before_action :valid_screen_name?

  before_action do
    self.sidebar_disabled = true

    if flash.empty? && !SearchCountLimitation.count_remaining?(user: current_user, session_id: egotter_visit_id)
      @without_alert_container = true
      flash.now[:notice] = too_many_searches_message
    end
  end

  def show
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user

    @screen_name = params[:screen_name]

    if params[:names].present?
      @prev_name, @next_name = decrypt_names(params[:names])
    end
  end

  private

  def decrypt_names(content)
    names = MessageEncryptor.new.decrypt(content).split(',')
    names.map { |n| n == 'empty' ? nil : n }
  rescue => e
    nil
  end
end
