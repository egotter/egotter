# == Schema Information
#
# Table name: egotter_followers
#
#  id          :bigint(8)        not null, primary key
#  screen_name :string(191)      not null
#  uid         :bigint(8)        not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_egotter_followers_on_created_at  (created_at)
#  index_egotter_followers_on_uid         (uid) UNIQUE
#

class EgotterFollower < ApplicationRecord
  validates_with Validations::ScreenNameValidator
  validates_with Validations::UidValidator
end
