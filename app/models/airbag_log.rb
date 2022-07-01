# == Schema Information
#
# Table name: airbag_logs
#
#  id         :bigint(8)        not null, primary key
#  severity   :string(191)      not null
#  message    :text(65535)
#  properties :json
#  time       :datetime         not null
#
# Indexes
#
#  index_airbag_logs_on_time               (time)
#  index_airbag_logs_on_time_and_severity  (time,severity)
#
class AirbagLog < ApplicationRecord
end
