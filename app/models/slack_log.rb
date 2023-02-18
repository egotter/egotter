# == Schema Information
#
# Table name: slack_logs
#
#  id         :bigint(8)        not null, primary key
#  channel    :string(191)
#  message    :text(65535)
#  properties :json
#  time       :datetime         not null
#
# Indexes
#
#  index_slack_logs_on_time  (time)
#
class SlackLog < ApplicationLogRecord
end
