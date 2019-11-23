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

  def perform!
    error_check! unless @error_check

    unless TwitterUser.exists?(uid: user.uid)
      send_initialization_message
      return
    end

    current_twitter_user = TwitterUser.latest_by(uid: user.uid)
    previous_twitter_user = TwitterUser.where.not(id: current_twitter_user.id).order(created_at: :desc).find_by(uid: user.uid)
    previous_twitter_user = current_twitter_user unless previous_twitter_user

    changes = unfollowers_changed = nil

    ApplicationRecord.benchmark("#{self.class} #{id} Setup parameters", level: :info) do
      if previous_twitter_user.id == current_twitter_user.id
        previous_uids = previous_twitter_user.unfollowerships.pluck(:follower_uid)
        current_uids = previous_uids
      else
        previous_uids = previous_twitter_user.calc_unfollower_uids
        current_uids = current_twitter_user.unfollowerships.pluck(:follower_uid)
      end

      changes = {
          twitter_user_id: [previous_twitter_user.id, current_twitter_user.id],
          followers_count: [previous_twitter_user.follower_uids.size, current_twitter_user.follower_uids.size],
          unfollowers_count: [previous_uids.size, current_uids.size],
          removed_uid: [previous_uids.first, current_uids.first],
      }

      unfollowers_changed = previous_uids != current_uids
    end

    ApplicationRecord.benchmark("#{self.class} #{id} Send report", level: :info) do
      send_report(changes, previous_twitter_user: previous_twitter_user, current_twitter_user: current_twitter_user, changed: unfollowers_changed)
    end
  end

  ACTIVE_DAYS = 14
  ACTIVE_DAYS_WARNING = 11

  def error_check!
    verify_credentials!

    previous_errors = CreatePromptReportLog.where(user_id: user.id).order(created_at: :desc).limit(3).pluck(:error_class)
    if previous_errors.size == 3 && previous_errors.all? { |err| err.present? }
      raise TooManyErrors
    end

    raise PermissionLevelNotEnough unless user.notification_setting.enough_permission_level?
    raise TooShortRequestInterval if too_short_request_interval?
    raise Unauthorized unless user.authorized?
    raise ReportDisabled unless user.dm_enabled?
    raise TooShortSendInterval unless user.dm_interval_ok?
    raise UserSuspended if suspended?
    raise TooManyFriends if SearchLimitation.too_many_friends?(user: user)
    raise EgotterBlocked if blocked?

    if TwitterUser.exists?(uid: user.uid)
      twitter_user = TwitterUser.latest_by(uid: user.uid)
      raise TooManyFriends if SearchLimitation.too_many_friends?(twitter_user: twitter_user)
      raise MaybeImportBatchFailed if twitter_user.no_need_to_import_friendships?
    end

    raise UserInactive unless user.active_access?(ACTIVE_DAYS)

    @error_check = true
  end

  def send_initialization_message
    CreatePromptReportInitializationMessageWorker.perform_async(user.id, create_prompt_report_request_id: id)
  end

  def send_report(changes, previous_twitter_user:, current_twitter_user:, changed: true)
    if changed
      CreatePromptReportRemovedMessageWorker.perform_async(
          user.id,
          changes_json: changes.to_json,
          previous_twitter_user_id: previous_twitter_user.id,
          current_twitter_user_id: current_twitter_user.id,
          create_prompt_report_request_id: id)
    else
      CreatePromptReportNotChangedMessageWorker.perform_async(
          user.id,
          changes_json: changes.to_json,
          previous_twitter_user_id: previous_twitter_user.id,
          current_twitter_user_id: current_twitter_user.id,
          create_prompt_report_request_id: id)
    end
  end

  private

  def verify_credentials!
    ApiClient.do_request_with_retry(internal_client, :verify_credentials, [])
  rescue Twitter::Error::Unauthorized => e
    if e.message == 'Invalid or expired token.'
      raise Unauthorized
    else
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      raise Unknown.new(e.message)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise Unknown.new(e.message)
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
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      raise Unknown.new(e.message)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise Unknown.new(e.message)
  end

  def fetch_user
    @fetch_user ||= client.user(user.uid)
  rescue Twitter::Error::Forbidden => e
    if e.message.start_with? 'To protect our users from spam and other malicious activity, this account is temporarily locked.'
      raise TemporarilyLocked.new(__method__.to_s)
    else
      logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      raise Unknown.new(e.message)
    end
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.class} #{e.message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    raise Unknown.new(e.message)
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

  class TwitterUserNotPersisted < DeadErrorTellsNoTales
  end

  class InitializationStarted < DeadErrorTellsNoTales
  end

  class InitializationMessageNotSent < DeadErrorTellsNoTales
  end

  class InitializationFailed < Error
  end

  class RemovedMessageNotSent < DeadErrorTellsNoTales
  end

  class NotChangedMessageNotSent < DeadErrorTellsNoTales
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

  class UnfollowersNotChanged < DeadErrorTellsNoTales
  end

  class MessageNotChanged < DeadErrorTellsNoTales
  end

  class FollowersCountNotChanged < DeadErrorTellsNoTales
  end

  class RemovedUidNotChanged < DeadErrorTellsNoTales
  end

  class DirectMessageNotSent < Error
  end

  class DuplicateJobSkipped < DeadErrorTellsNoTales
  end

  class Unknown < StandardError
  end
end
