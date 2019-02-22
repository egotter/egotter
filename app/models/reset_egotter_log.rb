# == Schema Information
#
# Table name: reset_egotter_logs
#
#  id            :bigint(8)        not null, primary key
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  message       :string(191)      default(""), not null
#  screen_name   :string(191)      not null
#  status        :boolean          default(FALSE), not null
#  uid           :bigint(8)        not null
#  created_at    :datetime         not null
#  session_id    :string(191)      not null
#  user_id       :integer          not null
#
# Indexes
#
#  index_reset_egotter_logs_on_created_at  (created_at)
#

class ResetEgotterLog < ApplicationRecord
  validates :session_id, presence: true
  validates :uid, presence: true
  validates :screen_name, presence: true

  def perform(send_dm: false)
    user = twitter_user
    unless user
      raise "Record of TwitterUser not found #{self.inspect}"
    end

    result = user.reset_data
    update(status: true)

    if send_dm
      DirectMessageRequest.new(User.find_by(uid: User::EGOTTER_UID).api_client.twitter, uid, I18n.t('settings.index.reset_egotter.direct_message')).perform
    end

    result
  end

  private

  def twitter_user
    TwitterUser.latest_by(uid: uid)
  end
end
