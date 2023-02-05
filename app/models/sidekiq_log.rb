# == Schema Information
#
# Table name: sidekiq_logs
#
#  id         :bigint(8)        not null, primary key
#  message    :text(65535)
#  properties :json
#  time       :datetime         not null
#
# Indexes
#
#  index_sidekiq_logs_on_time  (time)
#
class SidekiqLog < ApplicationLogRecord
end
