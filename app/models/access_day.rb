# == Schema Information
#
# Table name: access_days
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  date       :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_access_days_on_user_id_and_date  (user_id,date) UNIQUE
#

class AccessDay < ApplicationRecord
  belongs_to :user

  validates :user_id, presence: true
  validates :date, presence: true
end
