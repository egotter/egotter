# == Schema Information
#
# Table name: reset_egotter_requests
#
#  id          :bigint(8)        not null, primary key
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  session_id  :string(191)      not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_reset_egotter_requests_on_created_at  (created_at)
#  index_reset_egotter_requests_on_user_id     (user_id)
#

class ResetEgotterRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user

  validates :session_id, presence: true
  validates :user_id, presence: true

  def perform!(send_dm: false)
    raise AlreadyFinished.new("This request has already been finished. #{self.inspect}") if finished?

    twitter_user = user.twitter_user
    raise RecordNotFound.new("Record of TwitterUser not found #{self.inspect}") unless twitter_user

    result = twitter_user.reset_data
    send_goodbye_message if send_dm

    result
  end

  def perform(send_dm: false)
    perform!(send_dm: send_dm)
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")

    ResetEgotterLog.create(request_id: id, error_class: e.class, error_message: e.message.truncate(100))
  end

  private

  def send_goodbye_message
    DirectMessageRequest.new(User.find_by(uid: User::EGOTTER_UID).api_client.twitter, user.uid, I18n.t('settings.index.reset_egotter.direct_message')).perform
  rescue => e
    logger.warn "#{e.class} #{e.message}"
    logger.info e.backtrace.join("\n")
  end

  class RecordNotFound < StandardError
  end

  class AlreadyFinished < StandardError
  end
end
