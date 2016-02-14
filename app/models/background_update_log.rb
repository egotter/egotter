# == Schema Information
#
# Table name: background_update_logs
#
#  id         :integer          not null, primary key
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
#  index_background_update_logs_on_created_at  (created_at)
#  index_background_update_logs_on_uid         (uid)
#

class BackgroundUpdateLog < ActiveRecord::Base

  TOO_MANY_REQUESTS = 'too many requests'
  UNAUTHORIZED = 'unauthorized'
  TOO_MANY_FRIENDS = 'too many friends'
  SUSPENDED = 'suspended'
  RECENTLY_CREATED = 'recently created(or updated)'
  SOMETHING_IS_WRONG = 'something is wrong'

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

  DEFAULT_SECONDS = Rails.configuration.x.constants['background_update_log_recently_created_threshold']

  def recently_created?(seconds = DEFAULT_SECONDS)
    Time.zone.now.to_i - created_at.to_i < seconds
  end
end
