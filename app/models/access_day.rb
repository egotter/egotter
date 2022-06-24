# == Schema Information
#
# Table name: access_days
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  date       :date
#  time       :datetime
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

  def short_date
    words = date.to_s.split('-')
    words[1] + words[2]
  end

  class << self
    def current_date
      Time.zone.now.in_time_zone('Tokyo').to_date
    end
  end
end
