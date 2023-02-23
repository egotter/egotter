# == Schema Information
#
# Table name: customers
#
#  id                 :bigint(8)        not null, primary key
#  user_id            :bigint(8)        not null
#  stripe_customer_id :string(191)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_customers_on_created_at                      (created_at)
#  index_customers_on_user_id_and_stripe_customer_id  (user_id,stripe_customer_id) UNIQUE
#
class Customer < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :stripe_customer_id, presence: true

  def stripe_customer
    Stripe::Customer.retrieve(stripe_customer_id)
  end

  class << self
    def latest_by(condition)
      order(created_at: :desc).find_by(condition)
    end
  end
end
