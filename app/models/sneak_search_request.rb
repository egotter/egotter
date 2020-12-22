class SneakSearchRequest < ApplicationRecord
  validates :user_id, uniqueness: true
end
