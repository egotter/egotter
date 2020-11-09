# == Schema Information
#
# Table name: assemble_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  twitter_user_id :integer          not null
#  status          :string(191)      default(""), not null
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

    UpdateUsageStatWorker.perform_async(twitter_user.uid, user_id: twitter_user.user_id, location: self.class)
    UpdateAudienceInsightWorker.perform_async(twitter_user.uid, location: self.class)
    CreateFriendInsightWorker.perform_async(twitter_user.uid, location: self.class)
    CreateFollowerInsightWorker.perform_async(twitter_user.uid, location: self.class)
    CreateTopFollowerWorker.perform_async(twitter_user.id)

    perform_direct
  end

  private

  def perform_direct
    CreateTwitterUserCloseFriendsWorker.perform_async(twitter_user.id)

    return unless validate_record_friends!

    CreateTwitterUserOneSidedFriendsWorker.perform_async(twitter_user.id)
    CreateTwitterUserInactiveFriendsWorker.perform_async(twitter_user.id)
    CreateTwitterUserUnfriendsWorker.perform_async(twitter_user.id)

    twitter_user.update(statuses_interval: twitter_user.calc_statuses_interval)
    twitter_user.update(follow_back_rate: twitter_user.calc_follow_back_rate)
    twitter_user.update(reverse_follow_back_rate: twitter_user.calc_reverse_follow_back_rate)

    twitter_user.update(assembled_at: Time.zone.now)

    DeleteDisusedRecordsWorker.perform_async(twitter_user.uid)
  end

  def validate_record_creation_order!
    latest = TwitterUser.latest_by(uid: twitter_user.uid)

    if twitter_user.id != latest.id
      update(status: 'not_latest')
      false
    end

    if latest.assembled_at.present?
      update(status: 'already_assembled')
      false
    end

    true
  end

  def validate_record_friends!
    if twitter_user.too_little_friends?
      update(status: 'too_little_friends')
      false
    end

    if twitter_user.no_need_to_import_friendships?
      update(status: 'no_need_to_import')
      false
    end

    true
  end

  module Instrumentation
    def bm(message, &block)
      start = Time.zone.now
      yield
      @benchmark[message.to_s] = Time.zone.now - start if @benchmark
    end

    def perform!(*args, &blk)
      @benchmark = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @benchmark['sum'] = @benchmark.values.sum
      @benchmark['elapsed'] = elapsed

      logger.info "Benchmark AssembleTwitterUserRequest twitter_user_id=#{twitter_user_id} #{@benchmark.inspect}"
    end
  end
  prepend Instrumentation
end
