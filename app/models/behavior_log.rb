# == Schema Information
#
# Table name: behavior_logs
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :string(191)      default("-1"), not null
#  screen_name :string(191)      default(""), not null
#  json        :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_behavior_logs_on_screen_name  (screen_name)
#  index_behavior_logs_on_uid          (uid) UNIQUE
#  index_behavior_logs_on_user_id      (user_id) UNIQUE
#

class BehaviorLog < ActiveRecord::Base
end
