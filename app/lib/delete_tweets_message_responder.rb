class DeleteTweetsMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      20
    end

    def received?
      return false if @text.length > message_length

      if @text.match?(inquiry_regexp)
        @inquiry = true
      elsif @text.match?(start_regexp)
        @start = true
      end

      @inquiry || @start
    end

    def inquiry_regexp
      /削除|消去|全消し|ツイ消し|つい消し|クリーナ/
    end

    def start_regexp
      /\Aツイート削除 開始 (\w{5})\z/
    end

    def send_message
      if @inquiry
        CreateDeleteTweetsQuestionedMessageWorker.perform_async(@uid)
      elsif @start
        if (user = validate_report_status(@uid)) &&
            (request_token = @text.match(start_regexp)[0]) &&
            (request = DeleteTweetsRequest.where(user_id: user.id).find_by_token(request_token))
          DeleteTweetsWorker.perform_async(request.id, user_id: user.id)
          CreateDeleteTweetsRequestStartedMessageWorker.perform_async(@uid)
        else
          CreateDeleteTweetsInvalidRequestMessageWorker.perform_async(@uid)
        end
      end
    end
  end
end
