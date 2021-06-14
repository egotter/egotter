# == Schema Information
#
# Table name: violation_events
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  name       :string(191)
#  properties :json
#  time       :datetime         not null
#
# Indexes
#
#  index_violation_events_on_name_and_time  (name,time)
#  index_violation_events_on_time           (time)
#  index_violation_events_on_user_id        (user_id)
#
class ViolationEvent < ApplicationRecord
  belongs_to :user, optional: true

  before_validation do
    if time.nil?
      self.time = Time.zone.now
    end
  end
end
