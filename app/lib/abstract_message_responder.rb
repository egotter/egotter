class AbstractMessageResponder
  def initialize(uid, text)
    @processor = processor_class.new(uid, text)
  end

  def processor_class
    raise NotImplementedError
  end

  def respond
    if @processor.received?
      @processor.send_message
      return true
    end

    false
  rescue => e
    Airbag.warn e.inspect
    false
  end

  class << self
    def from_dm(dm)
      new(dm.sender_id, dm.text)
    end
  end
end
