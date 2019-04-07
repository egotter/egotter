# == Schema Information
#
# Table name: gauges
#
#  id    :bigint(8)        not null, primary key
#  name  :string(191)
#  label :string(191)
#  value :integer
#  time  :datetime
#
# Indexes
#
#  index_gauges_on_time  (time)
#

class Gauge < ApplicationRecord
  class << self
    def create_by_hash(name, hash)
      now = Time.zone.now
      hash.each do |label, value|
        create(name: name, label: label, value: value, time: now)
      end
    end
  end
end
