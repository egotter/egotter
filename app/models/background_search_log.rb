# == Schema Information
#
# Table name: background_search_logs
#
#  id         :integer          not null, primary key
#  user_id    :integer          default(-1), not null
#  uid        :string(191)      default("-1"), not null
#  bot_uid    :string(191)      default("-1"), not null
#  status     :boolean          default(FALSE), not null
#  reason     :string(191)      default(""), not null
#  message    :text(65535)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_background_search_logs_on_created_at          (created_at)
#  index_background_search_logs_on_uid                 (uid)
#  index_background_search_logs_on_user_id             (user_id)
#  index_background_search_logs_on_user_id_and_status  (user_id,status)
#

class BackgroundSearchLog < ActiveRecord::Base

  TooManyRequests = 'too many requests'
  Unauthorized = 'unauthorized'
  SomethingIsWrong = 'something is wrong'

  def self.processing?(uid)
    log = order(created_at: :desc).find_by(uid: uid)
    log.blank? || !log.recently_created?
  end

  def self.finish?(uid)
    log = order(created_at: :desc).find_by(uid: uid)
    log.present? && log.recently_created?
  end

  def self.success?(uid)
    log = order(created_at: :desc).find_by(uid: uid)
    finish?(uid) && log.status == true
  end

  def self.fail?(uid)
    log = order(created_at: :desc).find_by(uid: uid)
    finish?(uid) && log.status == false
  end

  def self.fail_reason(uid)
    raise 'confirm fail? returns true' unless fail?(uid)
    order(created_at: :desc).find_by(uid: uid).reason
  end

  def self.fail_message(uid)
    raise 'confirm fail? returns true' unless fail?(uid)
    order(created_at: :desc).find_by(uid: uid).message
  end

  def self.success_logs(user_id, limit)
    where(user_id: user_id, status: true).order(created_at: :desc).limit(limit)
  end

  def recently_created?(minutes = 5)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end
end
