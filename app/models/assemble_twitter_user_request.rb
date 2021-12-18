# == Schema Information
#
# Table name: assemble_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  twitter_user_id :integer          not null
#  status          :string(191)      default(""), not null
#  requested_by    :string(191)
#  finished_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_assemble_twitter_user_requests_on_created_at       (created_at)
#  index_assemble_twitter_user_requests_on_twitter_user_id  (twitter_user_id)
#

class AssembleTwitterUserRequest < ApplicationRecord
  include RequestRunnable
  belongs_to :twitter_user

  validates :twitter_user_id, presence: true

  def perform!
    return unless validate_record_creation_order!
    first_part(twitter_user.user_id, twitter_user.uid)

    return unless validate_record_friends!
    second_part
  end

  private

  def first_part(user_id, uid)
    UpdateUsageStatWorker.perform_async(uid, user_id: user_id, location: self.class)
    CreateFriendInsightWorker.perform_async(uid, location: self.class)
    CreateFollowerInsightWorker.perform_async(uid, location: self.class)
    CreateTopFollowerWorker.perform_async(twitter_user_id)
    CreateTwitterUserCloseFriendsWorker.perform_async(twitter_user_id)
  end

  def second_part
    CreateTwitterUserOneSidedFriendsWorker.perform_async(twitter_user_id)
    CreateTwitterUserInactiveFriendsWorker.perform_async(twitter_user_id)
    CreateTwitterUserUnfriendsWorker.perform_async(twitter_user_id)

    twitter_user.update(
        statuses_interval: twitter_user.calc_statuses_interval,
        follow_back_rate: twitter_user.calc_follow_back_rate,
        reverse_follow_back_rate: twitter_user.calc_reverse_follow_back_rate,
        assembled_at: Time.zone.now,
    )
  end

  def validate_record_creation_order!
    latest = TwitterUser.latest_by(uid: twitter_user.uid)

    if twitter_user.id != latest.id
      update(status: 'not_latest')
      return false
    end

    if latest.assembled_at.present?
      update(status: 'already_assembled')
      return false
    end

    true
  end

  def validate_record_friends!
    if twitter_user.too_little_friends?
      update(status: 'too_little_friends')
      twitter_user.update(assembled_at: Time.zone.now)
      return false
    end

    if twitter_user.no_need_to_import_friendships?
      update(status: 'no_need_to_import')
      twitter_user.update(assembled_at: Time.zone.now)
      return false
    end

    true
  end
end
