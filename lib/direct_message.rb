class DirectMessage

  def initialize(response)
    @response = response
  end

  def id
    @response.dig(:event, :id)
  end

  def text
    @response.dig(:event, :mesnilsage_create, :message_data, :text)
  end

  def truncated_message(at: 100)
    @truncated_message ||= text.to_s.remove(/\R/).gsub(%r{https?://[\S]+}, 'URL').truncate(at)
  end
end
