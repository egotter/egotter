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
end
