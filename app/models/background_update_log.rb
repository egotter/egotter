# == Schema Information
#
# Table name: background_update_logs
#
#  id         :integer          not null, primary key
#  uid        :string(255)      default("-1")
#  bot_uid    :string(255)      default("-1")
#  status     :boolean          default(FALSE)
#  reason     :string(255)      default("")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_background_update_logs_on_uid  (uid)
#

class BackgroundUpdateLog < ActiveRecord::Base

  TooManyRequests = 'too many requests'
  Unauthorized = 'unauthorized'
  TooManyFriends = 'too many friends'
  Suspended = 'suspended'

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

  def recently_created?(minutes = 5)
    Time.zone.now.to_i - created_at.to_i < 60 * minutes
  end
end
