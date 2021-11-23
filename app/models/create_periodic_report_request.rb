# == Schema Information
#
# Table name: create_periodic_report_requests
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  requested_by :string(191)
#  status       :string(191)      default(""), not null
#  finished_at  :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_create_periodic_report_requests_on_created_at  (created_at)
#  index_create_periodic_report_requests_on_user_id     (user_id)
#

class CreatePeriodicReportRequest < ApplicationRecord
  include RequestRunnable
  belongs_to :user

  validates :user_id, presence: true

  attr_accessor :check_web_access, :check_allotted_messages_count, :check_following_status, :check_interval, :check_credentials
  attr_accessor :worker_context

  def append_status(text)
    if status.blank?
      self.status = text
    else
      self.status = "#{status},#{text}"
    end

    self
  end

  def perform!
    return unless validate_report!

    if worker_context == CreatePeriodicReportWorker # TODO Replace by requested_by == 'batch'
      if PeriodicReportReportableFlag.exists?(user_id: user_id) || TwitterUser.where(uid: user.uid).where('created_at > ?', 3.hours.ago).exists?
        logger.info "Don't create new record id=#{id} user_id=#{user_id}"
      else
        create_new_twitter_user_record
      end
    else
      create_new_twitter_user_record
    end

    send_report!
  end

  # validator: for debugging
  def validate_report!(validator = nil)
    validator ||= PeriodicReportValidator.new(self)

    return if check_credentials && !validator.validate_credentials!
    return if check_following_status && !validator.validate_following_status!
    return if check_interval && !validator.validate_interval!
    return if check_allotted_messages_count && !validator.validate_messages_count!
    return if check_web_access && !validator.validate_web_access!

    true
  end

  def send_report!
    # If an administrator makes a request immediately after processing a user's request, it may be skipped
    jid = CreatePeriodicReportMessageWorker.perform_async(user_id, report_options_builder.build)
    update(status: 'message_skipped') unless jid
  end

  module Instrumentation
    %i(
      create_new_twitter_user_record
      send_report?
      report_options_builder
      send_report!
    ).each do |method_name|
      define_method(method_name) do |*args, &blk|
        bm_perform(method_name) { method(method_name).super_method.call(*args, &blk) }
      end
    end

    def bm_perform(message, &block)
      start = Time.zone.now
      result = yield
      @bm_perform[message] = Time.zone.now - start if @bm_perform
      result
    end

    def perform!(*args, &blk)
      @bm_perform = {}
      start = Time.zone.now

      result = super

      elapsed = Time.zone.now - start
      @bm_perform[:sum] = @bm_perform.values.sum
      @bm_perform[:elapsed] = elapsed
      @bm_perform.transform_values! { |v| sprintf("%.3f", v) }

      Rails.logger.info "Benchmark CreatePeriodicReportRequest user_id=#{user_id} request_id=#{id} #{@bm_perform.inspect}"

      result
    end
  end
  prepend Instrumentation

  def create_new_twitter_user_record
    request = CreateTwitterUserRequest.create(
        requested_by: self.class,
        user_id: user_id,
        uid: user.uid)

    task = CreateTwitterUserTask.new(request)
    task.start!(:reporting)

  rescue CreateTwitterUserRequest::Unauthorized,
      CreateTwitterUserRequest::TooShortCreateInterval,
      CreateTwitterUserRequest::TooLittleFriends,
      CreateTwitterUserRequest::SoftSuspended,
      CreateTwitterUserRequest::TemporarilyLocked,
      CreateTwitterUserRequest::NotChanged => e
    logger.info "#{self.class}##{__method__} #{e.inspect} request_id=#{id} create_request_id=#{request&.id}"
  rescue => e
    # TODO Log backtraces if the error is CreateTwitterUserRequest::Unknown
    logger.warn "#{self.class}##{__method__} #{e.inspect} request_id=#{id} create_request_id=#{request&.id}"
  end

  def report_options_builder
    @report_options_builder ||= ReportOptionsBuilder.new(self)
  end

  class ReportOptionsBuilder
    PERIOD_START = 1.day

    def initialize(request)
      @request = request

      @start_date = PERIOD_START.ago
      @end_date = Time.zone.now

      # To specify start_date, UnfriendsBuilder is used
      @unfriends_builder = UnfriendsBuilder.new(request.user.uid, start_date: @start_date, end_date: @end_date)
      @new_friends_builder = FriendsGroupBuilder.new(request.user.uid, users: @unfriends_builder.users)
    end

    def build
      first_user = TwitterUser.find_by(id: @unfriends_builder.first_user&.id)
      last_user = TwitterUser.find_by(id: @unfriends_builder.last_user&.id)
      latest_user = TwitterUser.latest_by(uid: @request.user.uid)

      unfriends = fetch_users(unfriend_uids)
      unfollowers = fetch_users(unfollower_uids)
      total_unfollowers = fetch_users(total_unfollower_uids, limit: 5)
      account_statuses = attach_status(unfriends + unfollowers + total_unfollowers).map { |s| s.slice(:uid, :screen_name, :account_status) }

      new_friend_uids = @new_friends_builder.new_friends.flatten.take(10)
      new_friends = TwitterDB::User.where_and_order_by_field(uids: new_friend_uids).map { |user| user.slice(:uid, :screen_name) }
      new_follower_uids = @new_friends_builder.new_followers.flatten.take(10)
      new_followers = TwitterDB::User.where_and_order_by_field(uids: new_follower_uids).map { |user| user.slice(:uid, :screen_name) }

      properties = {
          version: 1,
          request_id: @request.id,
          start_date: @start_date,
          end_date: @end_date,
          first_friends_count: first_user&.friends_count,
          first_followers_count: first_user&.followers_count,
          last_friends_count: last_user&.friends_count,
          last_followers_count: last_user&.followers_count,
          latest_friends_count: latest_user&.friends_count,
          latest_followers_count: latest_user&.followers_count,
          unfriends: unfriends.map(&:screen_name),
          unfriends_count: unfriend_uids.size,
          unfollowers: unfollowers.map(&:screen_name),
          unfollowers_count: unfollower_uids.size,
          total_unfollowers: total_unfollowers.map(&:screen_name),
          account_statuses: account_statuses,
          new_friends: new_friends,
          new_followers: new_followers,
          worker_context: @request.worker_context,
      }

      record = PeriodicReport.create!(user_id: @request.user.id, token: PeriodicReport.generate_token, message_id: '', properties: properties)
      {periodic_report_id: record.id, request_id: @request.id}
    end

    private

    def unfriend_uids
      @unfriend_uids ||= @unfriends_builder.unfriends.flatten.uniq
    end

    def unfollower_uids
      @unfollower_uids ||= @unfriends_builder.unfollowers.flatten.uniq
    end

    def total_unfollower_uids
      if unfollower_uids.empty?
        UnfriendsBuilder.new(@request.user.uid, end_date: Time.zone.now, limit: 20).unfollowers.flatten.uniq
      else
        []
      end
    end

    def fetch_users(uids, limit: 10)
      target_uids = uids.take(limit)
      return [] if target_uids.empty?

      users = TwitterDB::User.where_and_order_by_field(uids: target_uids)

      if target_uids.size != users.size
        missing_uids = target_uids - users.map(&:uid)
        Rails.logger.warn "#{self.class}##{__method__}: Import missing uids request=#{@request.slice(:id, :user_id, :requested_by, :created_at)} uids_size=#{target_uids.size} users_size=#{users.size} uids=#{target_uids} missing_uids=#{missing_uids}"
        CreateHighPriorityTwitterDBUserWorker.perform_async(missing_uids, user_id: @request.user_id, enqueued_by: "#{self.class}##{__method__}")

        dummy = DummyUser.new
        users = uids.map do |uid|
          if (index = users.index { |user| user.uid == uid })
            users[index]
          else
            dummy
          end
        end
      end

      users
    end

    class DummyUser
      attr_accessor :account_status

      def screen_name
        'deleted'
      end
    end

    def attach_status(users)
      return [] if users.empty?

      client = User.find(@request.user_id).api_client

      begin
        raw_users = client.users(users.map(&:uid))

        users.each do |user|
          if (raw_user = raw_users.find { |u| user.uid == u[:id] })
            user.account_status = raw_user[:suspended] ? 'suspended' : nil
          else
            user.account_status = 'not_found'
          end
        end

      rescue => e
        if TwitterApiStatus.not_found?(e)
          users.each { |u| u.account_status = 'not_found' }
        elsif TwitterApiStatus.suspended?(e)
          users.each { |u| u.account_status = 'suspended' }
        elsif TwitterApiStatus.no_user_matches?(e)
          users.each { |u| u.account_status = 'suspended' }
        else
          users.each { |u| u.account_status = 'error' }
        end
      end

      users
    rescue => e
      Rails.logger.warn "#{self.class}##{__method__}: #{e.inspect} request=#{@request.inspect}"
      []
    end
  end

  SHORT_INTERVAL = 3.hours

  class << self
    def fetch_last_request(include_user_id:, reject_id:)
      query = correctly_completed
      query = query.where(user_id: include_user_id) if include_user_id
      query = query.where.not(id: reject_id) if reject_id
      query.order(created_at: :desc).first
    end

    # TODO Fix
    def interval_too_short?(include_user_id:, reject_id:)
      last_request = fetch_last_request(include_user_id: include_user_id, reject_id: reject_id)
      last_request && last_request.finished_at > SHORT_INTERVAL.ago
    end

    def correctly_completed
      where(status: '').where.not(finished_at: nil)
    end
  end
end
