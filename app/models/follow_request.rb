# == Schema Information
#
# Table name: follow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :integer          not null
#  finished_at   :datetime
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
  validates :uid, numericality: :only_integer
  validates :user_id, uniqueness: {scope: :uid}

  scope :without_error, -> {where("error_message is null or error_message = '' or error_message like 'You are unable to follow more people at this time.%'")}

  scope :unprocessed, -> user_id {
    order(created_at: :asc).
        where(user_id: user_id, finished_at: nil).
        without_error

  }
end
