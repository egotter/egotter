class ProfilesController < ApplicationController
  before_action :valid_screen_name?

  before_action do
    self.sidebar_disabled = true
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
