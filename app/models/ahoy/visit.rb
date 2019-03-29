# == Schema Information
#
# Table name: ahoy_visits
#
#  id               :bigint(8)        not null, primary key
#  visit_token      :string(191)
#  visitor_token    :string(191)
#  user_id          :bigint(8)
#  ip               :string(191)
#  user_agent       :text(65535)
#  referrer         :text(65535)
#  referring_domain :string(191)
#  landing_page     :text(65535)
#  browser          :string(191)
#  os               :string(191)
#  device_type      :string(191)
#  started_at       :datetime         not null
#
# Indexes
#
#  index_ahoy_visits_on_started_at   (started_at)
#  index_ahoy_visits_on_user_id      (user_id)
#  index_ahoy_visits_on_visit_token  (visit_token) UNIQUE
#

class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true
end
