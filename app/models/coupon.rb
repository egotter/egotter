# == Schema Information
#
# Table name: coupons
#
#  id           :bigint(8)        not null, primary key
#  user_id      :integer          not null
#  search_count :integer          not null
#  expires_at   :datetime         not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_coupons_on_created_at  (created_at)
#  index_coupons_on_user_id     (user_id)
#
class Coupon < ApplicationRecord
end
