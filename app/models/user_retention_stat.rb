# == Schema Information
#
# Table name: user_retention_stats
#
#  id         :integer          not null, primary key
#  date       :datetime         not null
#  total      :integer          default(0), not null
#  1_days     :integer          default(0), not null
#  2_days     :integer          default(0), not null
#  3_days     :integer          default(0), not null
#  4_days     :integer          default(0), not null
#  5_days     :integer          default(0), not null
#  6_days     :integer          default(0), not null
#  7_days     :integer          default(0), not null
#  14_days    :integer          default(0), not null
#  30_days    :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_retention_stats_on_date  (date) UNIQUE
#

class UserRetentionStat < ActiveRecord::Base
end
