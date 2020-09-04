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
  include Concerns::Request::Runnable
  belongs_to :twitter_user

  validates :twitter_user_id, presence: true

  def perform!
    return unless validate_record_creation_order!

    UpdateUsageStatWorker.perform_async(twitter_user.uid, user_id: twitter_user.user_id, location: self.class)
    UpdateAudienceInsightWorker.perform_async(twitter_user.uid, location: self.class)
    CreateFriendInsightWorker.perform_async(twitter_user.uid, location: self.class)
    CreateFollowerInsightWorker.perform_async(twitter_user.uid, location: self.class)

    login_user = User.find_by(id: twitter_user.user_id)
    [
        S3::CloseFriendship,
        S3::FavoriteFriendship,
    ].each do |klass|
      bm("#{klass}(s3)") do
        uids = twitter_user.calc_uids_for(klass, login_user: login_user)
        klass.import_from!(twitter_user.uid, uids)
        uids.each_slice(100) do |uids_array|
          CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids_array), user_id: twitter_user.user_id, compressed: true, enqueued_by: self.class)
        end

        if klass == S3::CloseFriendship && uids.present?
          CreateCloseFriendsOgImageWorker.perform_async(twitter_user.uid, uids: uids)
        end
      end
    rescue => e
      logger.warn "#{klass}#import_from! #{e.class} #{e.message.truncate(100)} twitter_user_id=#{twitter_user.id}"
      logger.info e.backtrace.join("\n")
    end

    return unless validate_record_friends!

    [
        S3::OneSidedFriendship,
        S3::OneSidedFollowership,
        S3::MutualFriendship,
        S3::InactiveFriendship,
        S3::InactiveFollowership,
        S3::InactiveMutualFriendship,
        S3::Unfriendship,
        S3::Unfollowership,
        S3::MutualUnfriendship,
    ].each do |klass|
      bm("#{klass}(s3)") do
        uids = twitter_user.calc_uids_for(klass)
        klass.import_from!(twitter_user.uid, uids)
      end
    rescue => e
      logger.warn "#{klass}#import_from! #{e.class} #{e.message.truncate(100)} twitter_user_id=#{twitter_user.id}"
      logger.info e.backtrace.join("\n")
    end

    twitter_user.update(assembled_at: Time.zone.now)

    # cleanup
    CloseFriendship.delete_by_uid(twitter_user.uid)
    FavoriteFriendship.delete_by_uid(twitter_user.uid)
    OneSidedFriendship.delete_by_uid(twitter_user.uid)
    OneSidedFollowership.delete_by_uid(twitter_user.uid)
    InactiveFriendship.delete_by_uid(twitter_user.uid)
    InactiveFollowership.delete_by_uid(twitter_user.uid)
  end

  private

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
      @benchmark[message] = Time.zone.now - start
    end

    def perform!(*args, &blk)
      @benchmark = {}
      start = Time.zone.now

      super

      elapsed = Time.zone.now - start
      @benchmark['sum'] = @benchmark.values.sum
      @benchmark['elapsed'] = elapsed

      logger.info "Benchmark AssembleTwitterUserRequest twitter_user_id=#{twitter_user_id} #{sprintf("%.3f sec", elapsed)}"
      logger.info "Benchmark AssembleTwitterUserRequest twitter_user_id=#{twitter_user_id} #{@benchmark.inspect}"
    end
  end
  prepend Instrumentation
end
