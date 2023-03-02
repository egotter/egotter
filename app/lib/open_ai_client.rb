class OpenAiClient
  def chat(text)
    if text.match?(/\A[\p{Hiragana}|\p{Katakana}|A-Za-z0-9]\z/)
      text = I18n.t('ai.hello')
    end

    messages = [
        {role: 'system', content: I18n.t('ai.system_content')},
        {role: 'user', content: text},
    ]
    res = OpenAI::Client.new.chat(parameters: {model: 'gpt-3.5-turbo', messages: messages})
    message = res['choices'][0]['message']['content']

    if SpamMessageResponder::Processor.new(nil, message).received?
      I18n.t('ai.default_message')
    else
      message
    end
  rescue => e
    Airbag.exception e, text: text
    TEXT.sample + Kaomoji::KAWAII.sample
  end
end
