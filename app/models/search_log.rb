# == Schema Information
#
# Table name: search_logs
#
#  id          :bigint(8)        not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :bigint(8)        default(-1), not null
#  screen_name :string(191)      default(""), not null
#  controller  :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  cache_hit   :boolean          default(FALSE), not null
#  ego_surfing :boolean          default(FALSE), not null
#  method      :string(191)      default(""), not null
#  path        :string(191)      default(""), not null
#  params      :string(191)
#  status      :integer          default(-1), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  ip          :string(191)
#  user_agent  :string(191)      default(""), not null
#  referer     :text(65535)
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  medium      :string(191)      default(""), not null
#  ab_test     :string(191)      default(""), not null
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

class SearchLog < ApplicationRecord
  belongs_to :user, optional: true

  before_validation :truncate_attrs

  def truncate_attrs
    %i(via user_agent referer).each do |attr|
      self[attr] = self[attr].truncate(150) if self[attr]
    end
  end

  class << self
    def except_crawler
      # device_type NOT IN ('crawler', 'UNKNOWN') AND session_id != '-1'
      where.not(device_type: %w(crawler UNKNOWN), session_id: -1)
    end

    def with_login
      where.not(user_id: -1)
    end

    def user_ids(*args)
      except_crawler
          .with_login
          .where(*args)
          .uniq
          .pluck(:user_id)
    end

    def session_ids(*args)
      except_crawler
          .where(*args)
          .uniq
          .pluck(:session_id)
    end
  end

  def with_login?
    user_id != -1
  end

  def crawler?
    device_type == 'crawler' || session_id == '-1'
  end
end
