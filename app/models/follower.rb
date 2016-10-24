# == Schema Information
#
# Table name: followers
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
#  index_followers_on_created_at   (created_at)
#  index_followers_on_from_id      (from_id)
#  index_followers_on_screen_name  (screen_name)
#  index_followers_on_uid          (uid)
#

class Follower < ActiveRecord::Base
  belongs_to :twitter_user

  include Concerns::TwitterUser::Store
  include Concerns::TwitterUser::Equalizer
  include Concerns::TwitterUser::Inflections
end
