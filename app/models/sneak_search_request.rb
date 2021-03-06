# == Schema Information
#
# Table name: sneak_search_requests
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_sneak_search_requests_on_created_at  (created_at)
#  index_sneak_search_requests_on_user_id     (user_id) UNIQUE
#
class SneakSearchRequest < ApplicationRecord
  # TODO Rename to SneakSearchSettings
  validates :user_id, uniqueness: true
end
