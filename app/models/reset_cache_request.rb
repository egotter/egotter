# == Schema Information
#
# Table name: reset_cache_requests
#
#  id          :bigint(8)        not null, primary key
#  session_id  :string(191)      not null
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_reset_cache_requests_on_created_at  (created_at)
#  index_reset_cache_requests_on_user_id     (user_id)
#

class ResetCacheRequest < ApplicationRecord
  include RequestRunnable
  belongs_to :user

  validates :session_id, presence: true
  validates :user_id, presence: true

  def perform!
    raise AlreadyFinished if finished?
    raise NotImplementedError
  end

  class AlreadyFinished < StandardError
  end
end
