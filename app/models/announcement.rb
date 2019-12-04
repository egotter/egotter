# == Schema Information
#
# Table name: announcements
#
#  id         :bigint(8)        not null, primary key
#  status     :boolean          default(TRUE), not null
#  date       :string(191)      not null
#  message    :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_announcements_on_created_at  (created_at)
#

class Announcement < ApplicationRecord

  class << self
    def list
      @list ||= Announcement.where(status: true).order(created_at: :desc).limit(12)
    end
  end
end
