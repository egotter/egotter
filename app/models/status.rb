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

class Status < ApplicationRecord
  belongs_to :twitter_user

  include Concerns::Status::Store

  def self.slice_status_info(t_status)
    {
      uid: t_status[:user][:id],
      screen_name: t_status[:user][:screen_name],
      status_info: t_status.slice(*::Status::STATUS_SAVE_KEYS).to_json
    }
  end
end
