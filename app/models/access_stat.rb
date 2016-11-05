# == Schema Information
#
# Table name: access_stats
#
#  id         :integer          not null, primary key
#  date       :datetime         not null
#  0_days     :integer          default(0), not null
#  1_days     :integer          default(0), not null
#  3_days     :integer          default(0), not null
#  7_days     :integer          default(0), not null
#  14_days    :integer          default(0), not null
#  30_days    :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_access_stats_on_date  (date) UNIQUE
#

class AccessStat < ActiveRecord::Base
end
