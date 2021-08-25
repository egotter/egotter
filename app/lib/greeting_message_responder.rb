class GreetingMessageResponder < AbstractMessageResponder

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

      if @text.match?(morning_regexp)
        @morning = true
      elsif @text.match?(afternoon_regexp)
        @afternoon = true
      elsif @text.match?(evening_regexp)
        @evening = true
      elsif @text.match?(night_regexp)
        @night = true
      elsif @text.match?(talk_regexp)
        @talk = true
      elsif @text.match?(yes_regexp)
        @yes = true
      elsif @text.match?(sorry_regexp)
        @sorry = true
      elsif @text.match?(ok_regexp)
        @ok = true
      end
    end

    def morning_regexp
      /おはよう?(ございます)?/
    end

    def afternoon_regexp
      /こんにち[はわ]/
    end

    def evening_regexp
      /こんばん[はわ]/
    end

    def night_regexp
      /おやすみ(なさい)?/
    end

    def talk_regexp
      /えごったー/
    end

    def yes_regexp
      /\Aはい\z/
    end

    def sorry_regexp
      /す[い|み]ません(でした)?|ごめん(なさい)?/
    end

    def ok_regexp
      /\A(おけ|おう)\z/
    end

    def send_message
      if @morning
        CreateGreetingGoodMorningMessageWorker.perform_async(@uid)
      elsif @afternoon
        CreateGreetingGoodAfternoonMessageWorker.perform_async(@uid)
      elsif @evening
        CreateGreetingGoodEveningMessageWorker.perform_async(@uid)
      elsif @night
        CreateGreetingGoodNightMessageWorker.perform_async(@uid)
      elsif @talk
        CreateGreetingTalkMessageWorker.perform_async(@uid)
      elsif @yes
        CreateGreetingYesMessageWorker.perform_async(@uid)
      elsif @sorry
        CreateGreetingSorryMessageWorker.perform_async(@uid)
      elsif @ok
        CreateGreetingOkMessageWorker.perform_async(@uid)
      end
    end
  end
end
