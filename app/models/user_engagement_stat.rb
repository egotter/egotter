# == Schema Information
#
# Table name: user_engagement_stats
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
#  8_days     :integer          default(0), not null
#  9_days     :integer          default(0), not null
#  10_days    :integer          default(0), not null
#  11_days    :integer          default(0), not null
#  12_days    :integer          default(0), not null
#  13_days    :integer          default(0), not null
#  14_days    :integer          default(0), not null
#  15_days    :integer          default(0), not null
#  16_days    :integer          default(0), not null
#  17_days    :integer          default(0), not null
#  18_days    :integer          default(0), not null
#  19_days    :integer          default(0), not null
#  20_days    :integer          default(0), not null
#  21_days    :integer          default(0), not null
#  22_days    :integer          default(0), not null
#  23_days    :integer          default(0), not null
#  24_days    :integer          default(0), not null
#  25_days    :integer          default(0), not null
#  26_days    :integer          default(0), not null
#  27_days    :integer          default(0), not null
#  28_days    :integer          default(0), not null
#  29_days    :integer          default(0), not null
#  30_days    :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_user_engagement_stats_on_date  (date) UNIQUE
#

class UserEngagementStat < ActiveRecord::Base
end
