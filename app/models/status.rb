# == Schema Information
#
# Table name: statuses
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  status_info :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_statuses_on_created_at   (created_at)
#  index_statuses_on_from_id      (from_id)
#  index_statuses_on_screen_name  (screen_name)
#  index_statuses_on_uid          (uid)
#

class Status < ActiveRecord::Base
  belongs_to :twitter_user

  include Concerns::Status::Store

  with_options on: :create do |obj|
    obj.validates :uid, presence: true, numericality: :only_integer
    obj.validates :screen_name, format: {with: /\A[a-zA-Z0-9_]{1,20}\z/}
    obj.validates :status_info, presence: true
  end
end
