class OpenAiClient
  def chat(text)
    messages = [
        {role: 'system', content: I18n.t('ai.pretty_content')},
        {role: 'user', content: text},
    ]
    res = OpenAI::Client.new.chat(parameters: {model: 'gpt-3.5-turbo', messages: messages})
    res['choices'][0]['message']['content']
  rescue => e
    Airbag.exception e, text: text
    TEXT.sample + Kaomoji::KAWAII.sample
  end
end
