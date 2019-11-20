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
end