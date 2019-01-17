class DirectMessage

  def initialize(response)
    @response = response
  end

  def id
    @response[:event][:id]
  end

  def text
    @response[:event][:message_create][:message_data][:text]
  end
end
