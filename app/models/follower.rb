# == Schema Information
#
# Table name: followers
#
#  id          :integer          not null, primary key
#  uid         :string           not null
#  screen_name :string           not null
#  user_info   :text             not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_followers_on_screen_name  (screen_name)
#  index_followers_on_uid          (uid)
#

class Follower < ActiveRecord::Base
  belongs_to :twitter_user

  delegate *TwitterUser::SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :user_info_hash

  def user_info_hash
    @user_info_hash ||= Hashie::Mash.new(JSON.parse(user_info))
  end
end
