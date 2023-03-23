class OpenAiClient
  def chat!(text)
    if text.match?(/\A[\p{Hiragana}|\p{Katakana}|A-Za-z0-9]\z/) ||
        text.match?(/prompt|プロンプト/) ||
        spam_message?(text)
      return
    end

    messages = [
        {role: 'system', content: default_system_content},
        {role: 'user', content: text},
    ]
    @res = OpenAI::Client.new.chat(parameters: {model: 'gpt-3.5-turbo', messages: messages})
    message = @res['choices'][0]['message']['content']

    if spam_message?(message) ||
        default_system_content.split(/[、。]/).any? { |content| message.include?(content) }
      return
    end

    message
  end

  def chat(text)
    chat!(text)
  rescue => e
    Airbag.exception e, text: text, res: @res
    Kaomoji::KAWAII.sample
  end

  private

  def spam_message?(text)
    processor = SpamMessageResponder::Processor.new(nil, nil)
    text.length < processor.message_length && processor.spam_received?(text)
  end

  def default_system_content
    I18n.t('ai.system_content')
  end
end
