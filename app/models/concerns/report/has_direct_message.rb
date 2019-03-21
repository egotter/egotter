require 'active_support/concern'

module Concerns::Report::HasDirectMessage
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def fetch_dm_text
    user_client.direct_message(message_id, full_text: true).text
  end

  def truncated_message(dm, truncate_at: 100)
    dm.text.remove(/\R/).gsub(%r{https?://[\S]+}, 'URL').truncate(truncate_at)
  end
end