# == Schema Information
#
# Table name: unfollowers
#
#  id          :integer          not null, primary key
#  uid         :integer          not null
#  screen_name :string(191)      not null
#  user_info   :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_unfollowers_on_from_id  (from_id)
#

class Unfollower < ActiveRecord::Base
  belongs_to :twitter_user

  include Concerns::TwitterUser::Store
  include Concerns::TwitterUser::Inflections
end
