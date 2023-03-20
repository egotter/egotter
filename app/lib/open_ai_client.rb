class OpenAiClient
  def chat!(text)
    if text.match?(/\A[\p{Hiragana}|\p{Katakana}|A-Za-z0-9]\z/) ||
        text.match?(/prompt|プロンプト/) ||
        SpamMessageResponder::Processor.new(nil, nil).spam_received?(text)
      return
    end

    messages = [
        {role: 'system', content: I18n.t('ai.system_content')},
        {role: 'user', content: text},
    ]
    @res = OpenAI::Client.new.chat(parameters: {model: 'gpt-3.5-turbo', messages: messages})
    message = @res['choices'][0]['message']['content']

    if SpamMessageResponder::Processor.new(nil, nil).spam_received?(text) ||
        I18n.t('ai.system_content').split(/[、。]/).any? { |content| message.include?(content) }
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
end
