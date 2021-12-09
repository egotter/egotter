# == Schema Information
#
# Table name: direct_message_event_logs
#
#  id           :bigint(8)        not null, primary key
#  name         :string(191)
#  sender_id    :bigint(8)
#  recipient_id :bigint(8)
#  time         :datetime         not null
#
# Indexes
#
#  index_direct_message_event_logs_on_name_and_time  (name,time)
#  index_direct_message_event_logs_on_time           (time)
#
class DirectMessageEventLog < ApplicationRecord
  class << self
    def total_dm
      where(name: 'Send DM')
    end

    def passive_dm
      where(name: 'Send passive DM')
    end

    def active_dm
      where(name: 'Send active DM')
    end

    def dm_from_egotter
      where(name: 'Send DM from egotter')
    end

    def passive_dm_from_egotter
      where(name: 'Send passive DM from egotter')
    end

    def active_dm_from_egotter
      where(name: 'Send active DM from egotter')
    end
  end
end
