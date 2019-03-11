# == Schema Information
#
# Table name: reset_cache_logs
#
#  id            :bigint(8)        not null, primary key
#  session_id    :string(191)      default("-1"), not null
#  user_id       :integer          default(-1), not null
#  request_id    :integer          default(-1), not null
#  uid           :bigint(8)        default(-1), not null
#  screen_name   :string(191)      default(""), not null
#  status        :boolean          default(FALSE), not null
#  message       :string(191)      default(""), not null
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#
# Indexes
#
#  index_reset_cache_logs_on_created_at  (created_at)
#

class ResetCacheLog < ApplicationRecord
  include Concerns::Log::Runnable
end
