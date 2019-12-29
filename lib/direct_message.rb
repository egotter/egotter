class DirectMessage

  def initialize(response)
    raise EmptyResponse.new('Response is empty') if response.blank?
    @response = response
  end

  def id
    @response.dig(:event, :id)
  end

  def text
    @response.dig(:event, :message_create, :message_data, :text)
  end

  def truncated_message(at: 100)
    @truncated_message ||= text.to_s.remove(/\R/).gsub(%r{https?://[\S]+}, 'URL').truncate(at)
  end

  def sender_id
    @response.dig(:event, :message_create, :sender_id)&.to_i
  end

  class EmptyResponse < StandardError
  end
end
