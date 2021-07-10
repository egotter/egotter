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

      if @text.match?(start_regexp)
        @start = true
      elsif @text.match?(vague_regexp)
        @vague = true
      elsif @text.match?(inquiry_regexp)
        @inquiry = true
      end

      @start || @vague || @inquiry
    end

    def inquiry_regexp
      /削除|消去|全消し|ツイ消し|つい消し|クリーナ/
    end

    def start_regexp
      /ツイート削除(\s|　)*開始(\s|　)+(?<token>\w{6})/
    end

    def vague_regexp
      /ツイート削除(\s|　)*開始/
    end

    def send_message
      if @inquiry
        CreateDeleteTweetsQuestionedMessageWorker.perform_async(@uid)
      elsif @vague
        CreateDeleteTweetsInvalidRequestMessageWorker.perform_async(@uid)
      elsif @start
        if (user = validate_report_status(@uid)) &&
            (request_token = @text.match(start_regexp)[:token]) &&
            (request = DeleteTweetsRequest.where(user_id: user.id).find_by_token(request_token))
          DeleteTweetsWorker.perform_in(3.seconds, request.id)
          CreateDeleteTweetsRequestStartedMessageWorker.perform_async(@uid)
        else
          CreateDeleteTweetsInvalidRequestMessageWorker.perform_async(@uid)
        end
      end
    end
  end
end
