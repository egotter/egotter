# == Schema Information
#
# Table name: coupons
#
#  id               :bigint(8)        not null, primary key
#  user_id          :integer          not null
#  search_count     :integer          not null
#  stripe_coupon_id :string(191)
#  expires_at       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_coupons_on_created_at  (created_at)
#  index_coupons_on_user_id     (user_id)
#
class Coupon < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true

  scope :not_expired, -> { where('expires_at > ?', Time.zone.now) }
  scope :has_search_count, -> { where('search_count > 0') }
  scope :has_stripe_coupon_id, -> { where('stripe_coupon_id is not null') }
end
