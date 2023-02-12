# == Schema Information
#
# Table name: create_periodic_report_requests
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  requested_by :string(191)
#  status       :string(191)      default(""), not null
#  started_at   :datetime
#  finished_at  :datetime
#  failed_at    :datetime
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

  def current_period
    requested_by.to_s[/(morning|afternoon|night)/, 1]
  end

  def perform
    if started_at || finished_at || failed_at
      return
    end

    update(started_at: Time.zone.now)

    unless validate_report!
      update(finished_at: Time.zone.now)
      return
    end

    if worker_context == CreatePeriodicReportWorker # TODO Replace by requested_by == 'batch'
      if PeriodicReportReportableFlag.on?(user_id, current_period)
        Airbag.info 'Reportable flag found', id: id, user_id: user_id
      elsif TwitterUser.where(uid: user.uid).where('created_at > ?', 4.hours.ago).exists?
        Airbag.info 'Recent record found', id: id, user_id: user_id
      else
        Airbag.info 'Create new record', id: id, user_id: user_id
        create_new_twitter_user_record
      end
    else
      create_new_twitter_user_record
    end

    report = create_report
    create_job(report)

    update(finished_at: Time.zone.now)
  rescue => e
    update(failed_at: Time.zone.now, status: e.inspect.truncate(150))
    raise
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

  def create_report
    props = report_options_builder.build
    record = PeriodicReport.create!(user_id: user_id, token: PeriodicReport.generate_token, message_id: '', properties: props)

    if record.id.nil?
      raise SaveFailed.new("report=#{record.inspect} request=#{inspect}")
    end

    record
  end

  def create_job(report)
    # If an administrator makes a request immediately after processing a user's request, it may be skipped
    jid = CreatePeriodicReportMessageWorker.perform_async(user_id, periodic_report_id: report.id, request_id: id)
    update(status: 'message_skipped') unless jid
  end

  def create_new_twitter_user_record
    request = CreateTwitterUserRequest.create(
        requested_by: self.class,
        user_id: user_id,
        uid: user.uid)
    request.perform(:reporting)
  rescue CreateTwitterUserRequest::Unauthorized,
      CreateTwitterUserRequest::TooShortCreateInterval,
      CreateTwitterUserRequest::TooLittleFriends,
      CreateTwitterUserRequest::SoftSuspended,
      CreateTwitterUserRequest::TemporarilyLocked,
      CreateTwitterUserRequest::NotChanged => e
    Airbag.info "#{self.class}##{__method__} #{e.inspect}", request_id: id, create_request_id: request&.id
  rescue => e
    Airbag.exception e, method: __method__, request_id: id, create_request_id: request&.id
  end

  def report_options_builder
    @report_options_builder ||= ReportOptionsBuilder.new(self)
  end

  class ReportOptionsBuilder
    def initialize(request)
      @request = request

      @start_date = 1.day.ago
      @end_date = Time.zone.now

      # Want to find unfollowers for a period of this report
      @target_users = TwitterUser.select(:id, :uid, :screen_name, :created_at).
          creation_completed.
          where(uid: request.user.uid).
          where(created_at: @start_date..@end_date).
          order(created_at: :desc).
          limit(10).
          reverse
    end

    def build
      first_user = TwitterUser.find_by(id: @target_users.first&.id)
      last_user = TwitterUser.find_by(id: @target_users.last&.id)
      latest_user = TwitterUser.latest_by(uid: @request.user.uid)

      unfriends = fetch_users(unfriend_uids, context: 'unfriend')
      unfollowers = fetch_users(unfollower_uids, context: 'unfollower')
      total_unfollowers = fetch_users(total_unfollower_uids, context: 'total_unfollower')
      account_statuses = attach_status(unfriends + unfollowers + total_unfollowers).map { |s| s.slice(:uid, :screen_name, :account_status) }

      new_friend_uids = TwitterUser.calc_total_new_friend_uids(@target_users).uniq.take(10)
      new_friends = TwitterDB::User.order_by_field(new_friend_uids).where(uid: new_friend_uids).map { |user| user.slice(:uid, :screen_name) }
      new_follower_uids = TwitterUser.calc_total_new_follower_uids(@target_users).uniq.take(10)
      new_followers = TwitterDB::User.order_by_field(new_follower_uids).where(uid: new_follower_uids).map { |user| user.slice(:uid, :screen_name) }

      {
          version: 1,
          request_id: @request.id,
          twitter_user_ids: @target_users.map(&:id),
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
          worker_context: @request.worker_context.to_s,
      }
    end

    private

    def unfriend_uids
      @unfriend_uids ||= TwitterUser.calc_total_new_unfriend_uids(@target_users).uniq
    end

    def unfollower_uids
      @unfollower_uids ||= TwitterUser.calc_total_new_unfollower_uids(@target_users).uniq
    end

    def total_unfollower_uids
      if unfollower_uids.empty?
        twitter_users = TwitterUser.select(:id, :uid, :screen_name, :created_at).
            creation_completed.
            where(uid: @request.user.uid).
            order(created_at: :desc).limit(10).reverse
        TwitterUser.calc_total_new_unfollower_uids(twitter_users).uniq
      else
        []
      end
    end

    def fetch_users(uids, limit: 10, context: nil)
      target_uids = uids.take(limit)
      return [] if target_uids.empty?

      users = TwitterDB::User.order_by_field(target_uids).where(uid: target_uids)

      if target_uids.size != users.size
        missing_uids = target_uids - users.map(&:uid)
        Airbag.warn "#{self.class}##{__method__}: Import missing uids request=#{@request.slice(:id, :user_id, :requested_by, :created_at)} context=#{context} uids_size=#{target_uids.size} users_size=#{users.size} uids=#{target_uids} missing_uids=#{missing_uids}"
        CreateTwitterDBUserWorker.perform_async(missing_uids, user_id: @request.user_id, enqueued_by: "#{self.class}##{__method__}")

        users = uids.map do |uid|
          if (index = users.index { |user| user.uid == uid })
            users[index]
          else
            DummyUser.new(uid)
          end
        end
      end

      users
    end

    class DummyUser
      attr_accessor :account_status

      def initialize(uid)
        @uid = uid
      end

      def uid
        @uid
      end

      def screen_name
        'deleted'
      end

      def slice(*keys)
        {'uid' => @uid, 'screen_name' => screen_name, 'account_status' => account_status}
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
      Airbag.warn "#{self.class}##{__method__}: #{e.inspect} request=#{@request.inspect}"
      []
    end
  end

  SHORT_INTERVAL = 30.minutes

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

  class SaveFailed < StandardError
  end
end
