# == Schema Information
#
# Table name: follow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :integer
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_follow_requests_on_created_at  (created_at)
#  index_follow_requests_on_user_id     (user_id)
#

class FollowRequest < ActiveRecord::Base
  belongs_to :user
  validates :user_id, numericality: :only_integer

  scope :without_error, -> {where(error_class: [nil, ''])}
end
