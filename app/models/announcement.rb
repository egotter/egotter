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

  LIMIT = 12

  class << self
    def list
      if instance_variable_defined?(:@list)
        @list
      else
        records = Announcement.where(status: true).order(created_at: :desc).limit(LIMIT)
        logger.debug { "Load #{records.size} announcements" }
        @list = records
      end
    end
  end
end
