# == Schema Information
#
# Table name: followers
#
#  id          :integer          not null, primary key
#  uid         :string(255)      not null
#  screen_name :string(255)      not null
#  user_info   :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_followers_on_from_id      (from_id)
#  index_followers_on_screen_name  (screen_name)
#  index_followers_on_uid          (uid)
#

class Follower < ActiveRecord::Base
  belongs_to :twitter_user

  attr_accessor :client, :login_user, :egotter_context

  delegate *TwitterUser::PROFILE_SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :user_info_mash

  def user_info_mash
    @user_info_mash ||= Hashie::Mash.new(JSON.parse(user_info))
  end

  def has_key?(key)
    user_info_mash.has_key?(key)
  end

  include Concerns::TwitterUser::Validation

  def eql?(other)
    self.uid.to_i == other.uid.to_i
  end

  def hash
    self.uid.to_i.hash
  end
end
