class ChatMessageResponder < AbstractMessageResponder

  def processor_class
    Processor
  end

  class Processor
    include AbstractReportProcessor

    def message_length
      100
    end

    URL_REGEXP = %r(\Ahttps?://t\.co/\w+\z)
    USERNAME_REGEXP = %r(\A@\w+\z)

    def received?
      return false if @text.length > message_length
      return false if @text.match?(URL_REGEXP)
      return false if @text.match?(USERNAME_REGEXP)

      if @text.match?(thanks_regexp)
        @thanks = true
      elsif @text.match?(pretty_regexp)
        @pretty = true
      elsif @text.match?(morning_regexp)
        @morning = true
      elsif @text.match?(afternoon_regexp)
        @afternoon = true
      elsif @text.match?(evening_regexp)
        @evening = true
      elsif @text.match?(night_regexp)
        @night = true
      elsif @text.match?(yes_regexp)
        @yes = true
      elsif @text.match?(sorry_regexp)
        @sorry = true
      elsif @text.match?(ok_regexp)
        @ok = true
      elsif @text.match?(test_regexp)
        @test = true
      else
        @chat = true
      end
    end

    THANKS_REGEXP = Regexp.union(/ありがとう?|有難う|お疲れ様|おつかれさま/, /^(おつかれ|あり|ありごとー|あざす|あざっす|あざます|さんきゅ|てんきゅ|[好す]き|感謝)$/)

    def thanks_regexp
      THANKS_REGEXP
    end

    PRETTY_REGEXP = /アイコン|可愛い|かわいい|カワイイ/

    def pretty_regexp
      PRETTY_REGEXP
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

    def yes_regexp
      /\Aはい\z/
    end

    def sorry_regexp
      /す[い|み]ません(でした)?|ごめん(なさい)?/
    end

    def ok_regexp
      /\A(おけ|おう|OK|ok)\z/
    end

    TEST_REGEXP = Regexp.union(/DM送信テスト/, /^(DM届きました)$/)

    def test_regexp
      TEST_REGEXP
    end

    def send_message
      if @thanks
        CreateThankYouMessageWorker.perform_async(@uid, text: @text)
      elsif @pretty
        CreatePrettyIconMessageWorker.perform_async(@uid, text: @text)
      elsif @morning
        CreateGreetingGoodMorningMessageWorker.perform_async(@uid, text: @text)
      elsif @afternoon
        CreateGreetingGoodAfternoonMessageWorker.perform_async(@uid, text: @text)
      elsif @evening
        CreateGreetingGoodEveningMessageWorker.perform_async(@uid, text: @text)
      elsif @night
        CreateGreetingGoodNightMessageWorker.perform_async(@uid, text: @text)
      elsif @yes
        CreateGreetingYesMessageWorker.perform_async(@uid, text: @text)
      elsif @sorry
        CreateGreetingSorryMessageWorker.perform_async(@uid, text: @text)
      elsif @ok
        CreateGreetingOkMessageWorker.perform_async(@uid, text: @text)
      elsif @test
        CreateGreetingOkMessageWorker.perform_async(@uid, text: @text)
      elsif @chat
        CreateChatMessageWorker.perform_async(@uid, text: @text)
      end
    end
  end
end
