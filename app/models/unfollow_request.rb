class UnfollowRequest < ActiveRecord::Base
  belongs_to :user
  validates :user_id, numericality: :only_integer
  validates :uid, numericality: :only_integer
end
