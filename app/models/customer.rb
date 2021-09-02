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
  validates :user_id, presence: true
  validates :stripe_customer_id, presence: true
end
