class AnonymousMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def received?
      User.exists?(uid: @uid)
    end

    def send_message
      CreateAnonymousMessageWorker.perform_async(@uid)
    end
  end
end
