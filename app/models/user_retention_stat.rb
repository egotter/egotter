# == Schema Information
#
# Table name: user_retention_stats
#
#  id            :integer          not null, primary key
#  date          :datetime         not null
#  total         :integer          default(0), not null
#  1_days        :integer          default(0), not null
#  2_days        :integer          default(0), not null
#  3_days        :integer          default(0), not null
#  4_days        :integer          default(0), not null
#  5_days        :integer          default(0), not null
#  6_days        :integer          default(0), not null
#  7_days        :integer          default(0), not null
#  8_days        :integer          default(0), not null
#  9_days        :integer          default(0), not null
#  10_days       :integer          default(0), not null
#  11_days       :integer          default(0), not null
#  12_days       :integer          default(0), not null
#  13_days       :integer          default(0), not null
#  14_days       :integer          default(0), not null
#  15_days       :integer          default(0), not null
#  16_days       :integer          default(0), not null
#  17_days       :integer          default(0), not null
#  18_days       :integer          default(0), not null
#  19_days       :integer          default(0), not null
#  20_days       :integer          default(0), not null
#  21_days       :integer          default(0), not null
#  22_days       :integer          default(0), not null
#  23_days       :integer          default(0), not null
#  24_days       :integer          default(0), not null
#  25_days       :integer          default(0), not null
#  26_days       :integer          default(0), not null
#  27_days       :integer          default(0), not null
#  28_days       :integer          default(0), not null
#  29_days       :integer          default(0), not null
#  30_days       :integer          default(0), not null
#  after_1_days  :integer          default(0), not null
#  after_2_days  :integer          default(0), not null
#  after_3_days  :integer          default(0), not null
#  after_4_days  :integer          default(0), not null
#  after_5_days  :integer          default(0), not null
#  after_6_days  :integer          default(0), not null
#  after_7_days  :integer          default(0), not null
#  after_8_days  :integer          default(0), not null
#  after_9_days  :integer          default(0), not null
#  after_10_days :integer          default(0), not null
#  after_11_days :integer          default(0), not null
#  after_12_days :integer          default(0), not null
#  after_13_days :integer          default(0), not null
#  after_14_days :integer          default(0), not null
#  after_15_days :integer          default(0), not null
#  after_16_days :integer          default(0), not null
#  after_17_days :integer          default(0), not null
#  after_18_days :integer          default(0), not null
#  after_19_days :integer          default(0), not null
#  after_20_days :integer          default(0), not null
#  after_21_days :integer          default(0), not null
#  after_22_days :integer          default(0), not null
#  after_23_days :integer          default(0), not null
#  after_24_days :integer          default(0), not null
#  after_25_days :integer          default(0), not null
#  after_26_days :integer          default(0), not null
#  after_27_days :integer          default(0), not null
#  after_28_days :integer          default(0), not null
#  after_29_days :integer          default(0), not null
#  after_30_days :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_user_retention_stats_on_date  (date) UNIQUE
#

class UserRetentionStat < ApplicationRecord
end
