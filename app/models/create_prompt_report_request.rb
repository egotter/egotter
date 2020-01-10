# == Schema Information
#
# Table name: create_prompt_report_requests
#
#  id               :bigint(8)        not null, primary key
#  user_id          :integer          not null
#  skip_error_check :boolean          default(FALSE), not null
#  finished_at      :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
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

  # According to this value, the cache creation job is enqueued in CreatePromptReportTask.
  attr_accessor :kind

  ACTIVE_DAYS = 14
  ACTIVE_DAYS_WARNING = 7
  TOO_MANY_ERRORS_SIZE = 3
  PROCESS_REQUEST_INTERVAL = 1.hour

  class << self
    def interval_ng_user_ids
      where(created_at: PROCESS_REQUEST_INTERVAL.ago..Time.zone.now).
          select(:user_id).
          distinct.
          pluck(:user_id)
    end
  end

  def perform!(record_created)
    begin
      error_check!
    rescue UserInactive => e
      send_report_was_stopped_message!
      raise
    end

    unless TwitterUser.exists?(uid: user.uid)
      CreatePromptReportMessageWorker.perform_async(user.id, kind: :initialization, create_prompt_report_request_id: id)
      return
    end

    prompt_report =
        if user.notification_setting.report_if_changed?
          PromptReport.new
        else
          send_starting_confirmation_message!
        end

    report_options = ReportOptionsBuilder.new(user, self, record_created, prompt_report.id).build

    if user.notification_setting.report_if_changed?
      if self.kind == :you_are_removed
        CreatePromptReportMessageWorker.perform_async(user.id, report_options)
      else
        Sidekiq.logger.info "Don't send a report because the data has not changed #{self.inspect}"
      end
    else
      CreatePromptReportMessageWorker.perform_async(user.id, report_options)
    end
  end

  def error_check!
    return true if skip_error_check

    unless @error_check
      CreatePromptReportValidator.new(request: self).validate!
      @error_check = true
    end
  end

  def send_starting_confirmation_message!
    PromptReport.new(user_id: user.id).tap do |report|
      report.deliver_starting_message!
    end
  rescue PromptReport::StartingFailed => e
    raise StartingConfirmationFailed.new(e.message)
  end

  def send_report_was_stopped_message!
    PromptReport.new(user_id: user.id).tap do |report|
      report.deliver_report_was_stopped_message!
    end
  rescue PromptReport::StartingFailed => e
    raise ReportWasStoppedFailed.new(e.message)
  end

  class ReportOptionsBuilder
    def initialize(user, request, record_created, prompt_report_id)
      @user = user
      @request = request
      @record_created = record_created
      @prompt_report_id = prompt_report_id
    end

    def build
      current_twitter_user = latest
      previous_twitter_user = second_latest(current_twitter_user.id)
      previous_twitter_user = current_twitter_user unless previous_twitter_user

      changes_builder = ChangesBuilder.new(previous_twitter_user, current_twitter_user, record_created: @record_created)
      period_builder = PeriodBuilder.new(@record_created, previous_twitter_user, current_twitter_user)

      changes = nil
      ApplicationRecord.benchmark("Benchmark CreatePromptReportTask #{@request.id} Setup parameters", level: :info) do
        changes = changes_builder.build
        changes.merge!(period: period_builder.build)
        @request.kind = changes[:unfollowers_changed] ? :you_are_removed : :not_changed
      end

      {
          changes_json: changes.to_json,
          previous_twitter_user_id: previous_twitter_user.id,
          current_twitter_user_id: current_twitter_user.id,
          create_prompt_report_request_id: @request.id,
          kind: @request.kind,
          prompt_report_id: @prompt_report_id,
      }
    end

    def latest
      TwitterUser.latest_by(uid: @user.uid)
    end

    def second_latest(id)
      TwitterUser.where.not(id: id).latest_by(uid: @user.uid)
    end
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

  class PeriodBuilder
    attr_reader :record_created, :previous_twitter_user, :current_twitter_user

    def initialize(record_created, previous_twitter_user, current_twitter_user)
      @record_created = record_created
      @previous_twitter_user = previous_twitter_user
      @current_twitter_user = current_twitter_user
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
    def build
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
  end

  class Error < StandardError
  end

  class InitializationStarted < Error
  end

  class PermissionLevelNotEnough < Error
  end

  class TooShortRequestInterval < Error
    def initialize(request)
      super("The last time is #{request.created_at.to_s}.")
    end
  end

  class TooShortSendInterval < Error
    def initialize(user)
      super("The last time is #{user.notification_setting.last_dm_at.to_s}. The interval is #{user.notification_setting.report_interval}.")
    end
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

  class StartingConfirmationFailed < Error
  end

  class ReportWasStoppedFailed < Error
  end

  class Unknown < StandardError
  end
end
