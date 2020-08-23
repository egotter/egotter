class ProfilesController < ApplicationController
  before_action :valid_screen_name?

  before_action do
    self.sidebar_disabled = true

    if flash.empty? && !@search_count_limitation.count_remaining?
      @without_alert_container = true
      flash.now[:notice] = too_many_searches_message
    end
  end

  def show
    @user = TwitterDB::User.find_by(screen_name: params[:screen_name])
    @user = TwitterUser.latest_by(screen_name: params[:screen_name]) unless @user

    @screen_name = params[:screen_name]

    if !from_crawler? && params[:names].present?
      @prev_name, @next_name = decrypt_names(params[:screen_name], params[:names])
    end
  end

  private

  def decrypt_names(name, content)
    names = MessageEncryptor.new.decrypt(content).split(',')
    if (index = names.index(name))
      [names.fetch(index - 1), names.fetch(index + 1, names[0])]
    end
  rescue => e
    nil
  end
end
