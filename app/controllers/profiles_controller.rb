class ProfilesController < ApplicationController

  before_action { head :forbidden if twitter_dm_crawler? }
  before_action :reject_spam_access!
  before_action :valid_screen_name?

  def show
    @screen_name = params[:screen_name]
    @user = set_user(params[:screen_name])

    if params[:names].present? && user_signed_in?
      set_decrypt_names(params[:screen_name], params[:names])
    end
  end

  private

  def set_user(screen_name)
    user = TwitterDB::User.find_by(screen_name: screen_name)
    user = TwitterUser.latest_by(screen_name: screen_name) unless user
    user = TwitterUserDecorator.new(user) if user
    user
  end

  def set_decrypt_names(name, content)
    @indicator_names = MessageEncryptor.new.decrypt(content).split(',')
  rescue => e
  end
end
