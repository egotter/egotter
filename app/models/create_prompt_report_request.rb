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
  ACTIVE_DAYS_WARNING = 7

  def error_check!
    CreatePromptReportValidator.new(request: self).validate!
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

  private

  PROCESS_REQUEST_INTERVAL = 1.hour

  class Error < StandardError
  end

  class InitializationStarted < Error
  end

  class PermissionLevelNotEnough < Error
  end

  class TooShortRequestInterval < Error
  end

  class TooShortSendInterval < Error
  end

  class Unauthorized < Error
  end

  class Forbidden < Error
  end

  class ReportDisabled < Error
  end

  class UserInactive < Error
  end

  class UserSuspended < Error
  end

  class TooManyFriends < Error
  end

  class TooManyErrors < Error
  end

  class TemporarilyLocked < Error
  end

  class EgotterBlocked < Error
  end

  class MaybeImportBatchFailed < Error
  end

  class Unknown < StandardError
  end
end
