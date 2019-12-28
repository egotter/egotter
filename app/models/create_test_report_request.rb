# == Schema Information
#
# Table name: create_test_report_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_create_test_report_requests_on_created_at  (created_at)
#  index_create_test_report_requests_on_user_id     (user_id)
#

class CreateTestReportRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user
  has_many :logs, -> { order(created_at: :asc) }, foreign_key: :request_id, class_name: 'CreateTestReportLog'

  attr_reader :error

  validates :user_id, presence: true

  def perform!
    @error = {}
    error_check!

    unless user.notification_setting.dm_enabled?
      user.notification_setting.update(dm: true, prompt_report: true)
    end

    if @error && interval_error?(@error[:name])
      @error = nil
    end
  end

  def error_check!
    communication_test!
    CreatePromptReportRequest.new(user_id: user.id).error_check!
  rescue => e
    @error = {name: e.class, message: e.message.truncate(100)}
  end

  def communication_test!
    exception1 = nil
    begin
      DirectMessageClient.new(user.api_client.twitter).
          create_direct_message(User::EGOTTER_UID, I18n.t('dm.testMessage.communication_test', from: user.screen_name, to: User.egotter.screen_name))
    rescue => e
      exception1 = CannotSendDirectMessageFromUser.new(e.message)
    end

    exception2 = nil
    begin
      DirectMessageClient.new(User.egotter.api_client.twitter).
          create_direct_message(user.uid, I18n.t('dm.testMessage.communication_test', from: User.egotter.screen_name, to: user.screen_name))
    rescue => e
      exception2 = CannotSendDirectMessageFromEgotter.new(e.message)
    end

    if exception1 && exception2
      raise CannotSendDirectMessageAtAll
    else
      raise exception1 if exception1
      raise exception2 if exception2
    end
  end

  class CannotSendDirectMessageFromUser < StandardError
  end

  class CannotSendDirectMessageFromEgotter < StandardError
  end

  class CannotSendDirectMessageAtAll < StandardError
  end

  def interval_error?(error_class)
    [
        'CreatePromptReportRequest::TooShortSendInterval',
        'CreatePromptReportRequest::TooShortRequestInterval',
    ].include?(error_class)
  end
end
