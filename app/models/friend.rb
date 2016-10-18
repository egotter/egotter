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
#
# Indexes
#
#  index_friends_on_from_id  (from_id)
#

class Friend < ActiveRecord::Base
  belongs_to :twitter_user

  include Concerns::TwitterUser::Store
  include Concerns::TwitterUser::Equalizer
end
