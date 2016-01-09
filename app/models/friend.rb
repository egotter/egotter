class Friend < ActiveRecord::Base
  belongs_to :twitter_user

  delegate *TwitterUser::SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :user_info_hash

  def user_info_hash
    @user_info_hash ||= Hashie::Mash.new(JSON.parse(user_info))
  end
end
