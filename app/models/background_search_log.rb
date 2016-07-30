# == Schema Information
#
# Table name: background_search_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default("-1"), not null
#  screen_name :string(191)      default(""), not null
#  bot_uid     :string(191)      default("-1"), not null
#  status      :boolean          default(FALSE), not null
#  reason      :string(191)      default(""), not null
#  message     :text(65535)      not null
#  call_count  :integer          default(-1), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
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

  class Unauthorized < StandardError
    MESSAGE = 'unauthorized'
  end

  class TooManyRequests < StandardError
    MESSAGE = 'too many requests'
  end

  class SomethingError < StandardError
    MESSAGE = 'something is wrong'
  end

  def self.latest(uid, user_id)
    order(created_at: :desc).find_by(uid: uid, user_id: user_id)
  end

  def self.processing?(uid, user_id)
    log = latest(uid, user_id)
    log.blank? || !log.recently_created?
  end

  def self.finish?(uid, user_id)
    log = latest(uid, user_id)
    log.present? && log.recently_created?
  end

  def self.successfully_finished?(uid, user_id)
    finish?(uid, user_id) && latest(uid, user_id).status == true
  end

  def self.failed?(uid, user_id)
    finish?(uid, user_id) && latest(uid, user_id).status == false
  end

  def self.fail_reason!(uid, user_id)
    failed?(uid, user_id) ? latest(uid, user_id).reason : raise
  end

  def self.fail_message!(uid, user_id)
    failed?(uid, user_id) ? latest(uid, user_id).message : raise
  end

  def self.success_logs(user_id, limit)
    where(user_id: user_id, status: true).order(created_at: :desc).limit(limit)
  end

  DEFAULT_SECONDS = Rails.configuration.x.constants['background_search_log_recently_created']

  def recently_created?(seconds = DEFAULT_SECONDS)
    Time.zone.now.to_i - created_at.to_i < seconds
  end
end
