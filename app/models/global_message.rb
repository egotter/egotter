# == Schema Information
#
# Table name: global_messages
#
#  id         :bigint(8)        not null, primary key
#  text       :text(65535)      not null
#  expires_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_global_messages_on_created_at  (created_at)
#  index_global_messages_on_expires_at  (expires_at)
#
class GlobalMessage < ApplicationRecord
  validates :text, presence: true

  class << self
    def message_found?
      exists?(expires_at: nil)
    end

    def latest_message
      order(created_at: :desc).find_by(expires_at: nil)&.text
    end
  end
end
