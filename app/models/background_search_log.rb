# == Schema Information
#
# Table name: background_search_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default("-1"), not null
#  screen_name :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  bot_uid     :string(191)      default("-1"), not null
#  auto        :boolean          default(FALSE), not null
#  status      :boolean          default(FALSE), not null
#  reason      :string(191)      default(""), not null
#  message     :text(65535)      not null
#  call_count  :integer          default(-1), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  medium      :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_background_search_logs_on_created_at          (created_at)
#  index_background_search_logs_on_screen_name         (screen_name)
#  index_background_search_logs_on_uid                 (uid)
#  index_background_search_logs_on_user_id             (user_id)
#  index_background_search_logs_on_user_id_and_status  (user_id,status)
#

class BackgroundSearchLog < ActiveRecord::Base
  include Concerns::Log::Status

  validates :via, inclusion: { in: %w(top_input top_input2 top_button profile_modal search_history_profile search_history_input retry) }, allow_blank: true

  class Unauthorized
    MESSAGE = self.name.demodulize
  end

  class TooManyRequests
    MESSAGE = self.name.demodulize
  end

  class SomethingError
    MESSAGE = self.name.demodulize
  end

  def self.success_logs(user_id, limit: 20)
    where(user_id: user_id, status: true).order(created_at: :desc).limit(limit)
  end
end
