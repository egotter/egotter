# == Schema Information
#
# Table name: import_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  user_id         :integer          not null
#  twitter_user_id :integer          not null
#  finished_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_import_twitter_user_requests_on_created_at  (created_at)
#  index_import_twitter_user_requests_on_user_id     (user_id)
#

class ImportTwitterUserRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user, optional: true
  belongs_to :twitter_user

  validates :user_id, presence: true
  validates :twitter_user_id, presence: true

  def perform!
    bm('FavoriteFriendship') { import_favorite_friendship }
    bm('CloseFriendship') { import_close_friendship }

    return if twitter_user.no_need_to_import_friendships?

    bm('Unfollowership') { import_unfollowership }

    [
        Unfriendship,
        OneSidedFriendship,
        OneSidedFollowership,
        MutualFriendship,
        BlockFriendship,
        InactiveFriendship,
        InactiveFollowership,
        InactiveMutualFriendship,
    ].each do |klass|
      if klass == MutualFriendship
        bm("#{klass}(s3)") do
          uids = twitter_user.calc_mutual_friend_uids
          MutualFriendship.import_from!(twitter_user.uid, uids)
          S3::MutualFriendship.import_from!(twitter_user.uid, uids)
        end

      elsif klass == InactiveFriendship
        bm("#{klass}(s3)") do
          uids = twitter_user.calc_inactive_friend_uids
          S3::InactiveFriendship.import_from!(twitter_user.uid, uids)
        end

      elsif klass == InactiveFollowership
        bm("#{klass}(s3)") do
          uids = twitter_user.calc_inactive_follower_uids
          S3::InactiveFollowership.import_from!(twitter_user.uid, uids)
        end

      elsif klass == InactiveMutualFriendship
        bm("#{klass}(s3)") do
          uids = twitter_user.calc_inactive_mutual_friend_uids
          InactiveMutualFriendship.import_from!(twitter_user.uid, uids)
          S3::InactiveMutualFriendship.import_from!(twitter_user.uid, uids)
        end

      elsif klass == OneSidedFriendship
        bm("#{klass}(s3)") do
          uids = twitter_user.calc_one_sided_friend_uids
          OneSidedFriendship.import_from!(twitter_user.uid, uids)
          S3::OneSidedFriendship.import_from!(twitter_user.uid, uids)
        end

      elsif klass == OneSidedFollowership
        bm("#{klass}(s3)") do
          uids = twitter_user.calc_one_sided_follower_uids
          OneSidedFollowership.import_from!(twitter_user.uid, uids)
          S3::OneSidedFollowership.import_from!(twitter_user.uid, uids)
        end

      else
        bm(klass.to_s) { klass.import_by!(twitter_user: twitter_user) }
      end
    rescue => e
      logger.warn "#{klass} #{e.class} #{e.message.truncate(100)} #{twitter_user.id}"
      logger.info e.backtrace.join("\n")
    end
  end

  def import_unfollowership
    Unfollowership.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), user_id: user_id, compressed: true, force_update: true, enqueued_by: self.class)
    end
  rescue => e
    logger.warn "#{klass} #{e.class} #{e.message.truncate(100)} #{twitter_user.id}"
    logger.info e.backtrace.join("\n")
  end

  def import_favorite_friendship
    FavoriteFriendship.import_by!(twitter_user: twitter_user).each_slice(100) do |uids|
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), user_id: user_id, compressed: true, enqueued_by: self.class)
    end
  rescue => e
    logger.warn "#{__method__} #{e.class} #{e.message.truncate(100)} #{twitter_user.id}"
    logger.info e.backtrace.join("\n")
  end

  def import_close_friendship
    CloseFriendship.import_by!(twitter_user: twitter_user, login_user: user).each_slice(100) do |uids|
      CreateTwitterDBUserWorker.perform_async(CreateTwitterDBUserWorker.compress(uids), user_id: user_id, compressed: true, enqueued_by: self.class)
    end
  rescue => e
    logger.warn "#{__method__} #{e.class} #{e.message.truncate(100)} #{twitter_user.id}"
    logger.info e.backtrace.join("\n")
  end

  def client
    if instance_variable_defined?(:@client)
      @client
    else
      @client = user ? user.api_client : Bot.api_client
    end
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

      logger.info "Benchmark ImportTwitterUserRequest twitter_user_id=#{twitter_user.id} #{sprintf("%.3f sec", elapsed)}"
      logger.info "Benchmark ImportTwitterUserRequest twitter_user_id=#{twitter_user_id} #{@benchmark.inspect}"
    end
  end
  prepend Instrumentation
end
