# == Schema Information
#
# Table name: reset_egotter_requests
#
#  id          :bigint(8)        not null, primary key
#  session_id  :string(191)      not null
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_reset_egotter_requests_on_created_at  (created_at)
#  index_reset_egotter_requests_on_user_id     (user_id)
#

class ResetEgotterRequest < ApplicationRecord
  include Concerns::RequestRunnable
  belongs_to :user
  has_many :logs, -> { order(created_at: :asc) }, foreign_key: :request_id, class_name: 'ResetEgotterLog'

  validates :session_id, presence: true
  validates :user_id, presence: true

  def perform!(send_dm: false)
    raise AlreadyFinished.new("request_id=#{id} user_id=#{user_id}") if finished?

    twitter_user = TwitterUser.latest_by(uid: user.uid)
    raise TwitterUserNotFound.new("request_id=#{id} user_id=#{user_id}") unless twitter_user

    result = twitter_user.reset_data
    send_goodbye_message if send_dm

    result
  end

  private

  def send_goodbye_message
    template = Rails.root.join('app/views/reset_egotter/goodbye.ja.text.erb')
    message = ERB.new(template.read).result
    user.api_client.create_direct_message_event(User::EGOTTER_UID, message)
  rescue => e
    if AccountStatus.invalid_or_expired_token?(e) ||
        DirectMessageStatus.cannot_send_messages?(e) ||
        DirectMessageStatus.not_following_you?(e) ||
        DirectMessageStatus.you_have_blocked?(e)
      # Do nothing
    else
      logger.warn "#{self.class}##{__method__}: #{e.inspect} request_id=#{id} user_id=#{user_id}"
      logger.info e.backtrace.join("\n")
    end
  end

  class TwitterUserNotFound < StandardError; end

  class AlreadyFinished < StandardError; end
end
