# == Schema Information
#
# Table name: friends
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  user_info   :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_friends_on_created_at   (created_at)
#  index_friends_on_from_id      (from_id)
#  index_friends_on_screen_name  (screen_name)
#  index_friends_on_uid          (uid)
#

class Friend < ActiveRecord::Base
  belongs_to :twitter_user

  attr_accessor :client, :login_user, :egotter_context, :without_friends

  include Concerns::TwitterUser::UserInfoAccessor
  include Concerns::TwitterUser::Validation

  def eql?(other)
    self.uid.to_i == other.uid.to_i
  end

  def hash
    self.uid.to_i.hash
  end
end
