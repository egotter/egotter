# == Schema Information
#
# Table name: search_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default(""), not null
#  screen_name :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  ego_surfing :boolean          default(FALSE), not null
#  method      :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  landing     :boolean          default(FALSE), not null
#  medium      :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_search_logs_on_action          (action)
#  index_search_logs_on_created_at      (created_at)
#  index_search_logs_on_screen_name     (screen_name)
#  index_search_logs_on_session_id      (session_id)
#  index_search_logs_on_uid             (uid)
#  index_search_logs_on_uid_and_action  (uid,action)
#  index_search_logs_on_user_id         (user_id)
#

class SearchLog < ActiveRecord::Base

  def self.except_crawler
    where.not(device_type: %w(crawler UNKNOWN))
  end

  def unify_referer
    self.unified_referer = unify_host(URI.parse(referer).host)
  end

  def unify_channel
    self.unified_channel = unify_host(channel)
  end

  private

  def unify_host(host)
    case
      when host.blank? then 'NULL'
      when host.include?('egotter') then 'EGOTTER'
      when host.include?('google') then 'GOOGLE'
      when host.include?('yahoo') then 'YAHOO'
      when host.include?('naver') then 'NAVER'
      when host.match(/(mobile\.)?twitter\.com|t\.co/) then 'TWITTER'
      else host
    end
  end
end
