class DeleteTweetsByArchiveResponder < AbstractMessageResponder

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

      if @text.match?(ok_regexp)
        @ok = true
      elsif @text.match?(stop_regexp)
        @stop = true
      elsif @text.match?(change_regexp)
        @change = true
      end

      @ok || @stop || @change
    end

    def ok_regexp
      /アーカイブ削除(\s|　)*[oOＯ][kKＫ]/
    end

    def stop_regexp
      /アーカイブ削除(\s|　)*停止/
    end

    def change_regexp
      /アーカイブ削除(\s|　)*(変更|更新)/
    end

    def send_message
      if @ok
        # Do nothing
      elsif @stop || @change
        # TODO Verify that the request really exists
        CreateDeleteTweetsByArchiveStopRequestedMessageWorker.perform_async(@uid)
      end
    end
  end
end
