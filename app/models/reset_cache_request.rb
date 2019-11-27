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
  include Concerns::Request::Runnable
  belongs_to :user

  validates :session_id, presence: true
  validates :user_id, presence: true

  def perform!
    raise AlreadyFinished if finished?

    if TwitterUser.exists?(uid: user.uid)
      twitter_user = TwitterUser.latest_by(uid: user.uid)

      Unfriendship.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
        CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), compressed: true)
      end

      Unfollowership.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
        CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), compressed: true, force_update: true)
      end
    end

    UpdateEgotterFollowersWorker.perform_async(user_id: user.id, enqueued_at: Time.zone.now)
  end

  class AlreadyFinished < StandardError
  end
end
