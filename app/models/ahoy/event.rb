# == Schema Information
#
# Table name: ahoy_events
#
#  id         :bigint(8)        not null, primary key
#  visit_id   :bigint(8)
#  user_id    :bigint(8)
#  name       :string(191)
#  properties :json
#  time       :datetime         not null
#
# Indexes
#
#  index_ahoy_events_on_name_and_time  (name,time)
#  index_ahoy_events_on_time           (time)
#  index_ahoy_events_on_user_id        (user_id)
#  index_ahoy_events_on_visit_id       (visit_id)
#

class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods

  self.table_name = "ahoy_events"

  belongs_to :visit
  belongs_to :user, optional: true

  class << self
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
