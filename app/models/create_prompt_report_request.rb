# == Schema Information
#
# Table name: create_prompt_report_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_create_prompt_report_requests_on_created_at  (created_at)
#  index_create_prompt_report_requests_on_user_id     (user_id)
#

class CreatePromptReportRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user
  has_many :logs, -> { order(created_at: :asc) }, foreign_key: :request_id, class_name: 'CreatePromptReportLog'

  validates :user_id, presence: true

  attr_accessor :kind

  def perform!(record_created)
    error_check! unless @error_check

    unless TwitterUser.exists?(uid: user.uid)
      CreatePromptReportMessageWorker.perform_async(user.id, kind: :initialization, create_prompt_report_request_id: id)
      return
    end

    current_twitter_user = TwitterUser.latest_by(uid: user.uid)
    previous_twitter_user = TwitterUser.where.not(id: current_twitter_user.id).order(created_at: :desc).find_by(uid: user.uid)
    previous_twitter_user = current_twitter_user unless previous_twitter_user

    changes = nil
    ApplicationRecord.benchmark("CreatePromptReportRequest #{id} Setup parameters", level: :info) do
      changes = ChangesBuilder.new(previous_twitter_user, current_twitter_user, record_created: record_created).build
      changes.merge!(period: calculate_period(record_created, previous_twitter_user, current_twitter_user))
      self.kind = changes[:unfollowers_changed] ? :you_are_removed : :not_changed
    end

    send_report(changes, previous_twitter_user, current_twitter_user)
  end

  class ChangesBuilder
    attr_reader :previous_twitter_user, :current_twitter_user, :record_created

    def initialize(previous_twitter_user, current_twitter_user, record_created:)
      @previous_twitter_user = previous_twitter_user
      @current_twitter_user = current_twitter_user
      @record_created = record_created
    end

    # There is one record. (prev.id == cur.id)
    #   There is no diff between previous record and current record.
    #
    # There are more than 2 records. (prev.id != cur.id)
    #   There is no diff if current record was not created immediately before.
    #
    def build
      if previous_twitter_user.id == current_twitter_user.id
        previous_uids = previous_twitter_user.unfollower_uids
        current_uids = previous_uids
        changed = false
      elsif !record_created
        previous_uids = previous_twitter_user.calc_unfollower_uids
        current_uids = current_twitter_user.unfollower_uids
        changed = false
      else
        #
        previous_uids = previous_twitter_user.calc_unfollower_uids
        current_uids = current_twitter_user.unfollower_uids

        previous_size = previous_uids.size
        current_size = current_uids.size

        if previous_size < current_size
          changed = previous_uids != current_uids.take(previous_size)
        elsif previous_size > current_size
          changed = previous_uids.take(current_size) != current_uids
        else
          changed = previous_uids != current_uids
        end
      end

      {
          unfollowers_changed: changed,
          twitter_user_id: [previous_twitter_user.id, current_twitter_user.id],
          followers_count: [previous_twitter_user.follower_uids.size, current_twitter_user.follower_uids.size],
          unfollowers_count: [previous_uids.size, current_uids.size],
          removed_uid: [previous_uids.first, current_uids.first],
      }
    end
  end

  # 1. There are more than 2 records (prev.id != cur.id)
  #   New record was created
  #     Unfollowers were changed
  #       prev <-> cur
  #     Unfollowers were NOT changed
  #       prev <-> cur
  #   New record was NOT created
  #     Unfollowers were NOT changed
  #       cur <-> now
  #
  # 2. There is one record (prev.id == cur.id)
  #   New record was created
  #     cur <-> cur
  #   New record was NOT created
  #     cur <-> now
  #
  def calculate_period(record_created, previous_twitter_user, current_twitter_user)
    records_size = TwitterUser.where(uid: previous_twitter_user.uid).size

    if records_size >= 2
      if record_created
        {start: previous_twitter_user.created_at, end: current_twitter_user.created_at}
      else
        {start: current_twitter_user.created_at, end: Time.zone.now}
      end
    elsif records_size == 1
      if record_created
        {start: current_twitter_user.created_at, end: current_twitter_user.created_at}
      else
        {start: current_twitter_user.created_at, end: Time.zone.now}
      end
    else
      raise "There are no records."
    end
  end

  ACTIVE_DAYS = 14
  ACTIVE_DAYS_WARNING = 11

  def error_check!
    verify_credentials!

    raise TooManyErrors if too_many_errors?
    raise PermissionLevelNotEnough unless user.notification_setting.enough_permission_level?
    raise TooShortRequestInterval if too_short_request_interval?
    raise Unauthorized unless user.authorized?
    raise ReportDisabled unless user.notification_setting.dm_enabled?
    raise TooShortSendInterval unless user.notification_setting.prompt_report_interval_ok?
    raise UserSuspended if suspended?
    raise TooManyFriends if SearchLimitation.limited?(fetch_user, signed_in: true)
    raise EgotterBlocked if blocked?

    if TwitterUser.exists?(uid: user.uid)
      twitter_user = TwitterUser.latest_by(uid: user.uid)
      raise TooManyFriends if SearchLimitation.limited?(twitter_user, signed_in: true)
      raise MaybeImportBatchFailed if twitter_user.no_need_to_import_friendships?
    end

    raise UserInactive unless user.active_access?(ACTIVE_DAYS)

    @error_check = true
  end

  def send_report(changes, previous_twitter_user, current_twitter_user)
    options = {
        changes_json: changes.to_json,
        previous_twitter_user_id: previous_twitter_user.id,
        current_twitter_user_id: current_twitter_user.id,
        create_prompt_report_request_id: id,
        kind: self.kind,
    }
    CreatePromptReportMessageWorker.perform_async(user.id, options)
  end

  TOO_MANY_ERRORS_SIZE = 3

  # Notice: If the InitializationStarted occurs three times,
  # you will not be able to send a message.
  def too_many_errors?
    errors = CreatePromptReportLog.where(user_id: user.id).
        where.not(request_id: id).
        order(created_at: :desc).
        limit(3).
        pluck(:error_class)

    (errors.size == TOO_MANY_ERRORS_SIZE && errors.all? { |err| err.present? }).tap do |val|
      # Save this value in Redis since it is difficult to retrieve this value efficiently with SQL.
      if val
        (@too_many_errors_users ||= TooManyErrorsUsers.new).add(user.id) # The ivar is used for testing
      end
    end
  end

  private

  def verify_credentials!
    ApiClient.do_request_with_retry(internal_client, :verify_credentials, [])
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      raise Unauthorized
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  rescue => e
    raise Unknown.new("#{__method__} #{e.class} #{e.message}")
  end

  PROCESS_REQUEST_INTERVAL = 1.hour

  def too_short_request_interval?
    self.class.where(user_id: user.id).
        where(created_at: PROCESS_REQUEST_INTERVAL.ago..Time.zone.now).
        where.not(id: id).exists?
  end

  def suspended?
    fetch_user[:suspended]
  end

  def blocked?
    if BlockedUser.exists?(uid: fetch_user[:id])
      true
    else
      blocked = client.blocked_ids.include? User::EGOTTER_UID
      CreateBlockedUserWorker.perform_async(fetch_user[:id], fetch_user[:screen_name]) if blocked
      blocked
    end
  rescue Twitter::Error::Forbidden => e
    if e.message.start_with?('To protect our users from spam and other malicious activity, this account is temporarily locked.')
      raise TemporarilyLocked.new(__method__.to_s)
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  rescue => e
    raise Unknown.new("#{__method__} #{e.class} #{e.message}")
  end

  def fetch_user
    @fetch_user ||= client.user(user.uid)
  rescue Twitter::Error::Forbidden => e
    if e.message.start_with? 'To protect our users from spam and other malicious activity, this account is temporarily locked.'
      raise TemporarilyLocked.new("#{__method__}: #{e.class} #{e.message}")
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  rescue => e
    raise Unknown.new("#{__method__} #{e.class} #{e.message}")
  end

  def client
    @client ||= user.api_client
  end

  def internal_client
    @internal_client ||= client.twitter
  end

  class Error < StandardError
  end

  class DeadErrorTellsNoTales < Error
    def initialize(*args)
      super('')
    end
  end

  class InitializationStarted < DeadErrorTellsNoTales
  end

  class PermissionLevelNotEnough < DeadErrorTellsNoTales
  end

  class TooShortRequestInterval < DeadErrorTellsNoTales
  end

  class TooShortSendInterval < DeadErrorTellsNoTales
  end

  class Unauthorized < DeadErrorTellsNoTales
  end

  class Forbidden < DeadErrorTellsNoTales
  end

  class ReportDisabled < DeadErrorTellsNoTales
  end

  class UserInactive < DeadErrorTellsNoTales
  end

  class UserSuspended < DeadErrorTellsNoTales
  end

  class TooManyFriends < DeadErrorTellsNoTales
  end

  class TooManyErrors < DeadErrorTellsNoTales
  end

  class TemporarilyLocked < Error
  end

  class EgotterBlocked < DeadErrorTellsNoTales
  end

  class MaybeImportBatchFailed < DeadErrorTellsNoTales
  end

  class Unknown < StandardError
  end
end
