# == Schema Information
#
# Table name: follow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :integer          not null
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_follow_requests_on_created_at       (created_at)
#  index_follow_requests_on_user_id_and_uid  (user_id,uid) UNIQUE
#

class FollowRequest < ActiveRecord::Base
  belongs_to :user
  validates :user_id, numericality: :only_integer
  validates :uid, numericality: :only_integer

  scope :without_error, -> {where("error_message is null or error_message = '' or error_message like 'You are unable to follow more people at this time.%'")}
end
