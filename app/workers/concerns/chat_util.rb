module ChatUtil
  def generate_chat(text, options = {})
    res = OpenAiClient.new.chat!(text)
  rescue => e
    Airbag.exception e, text: text, options: options
    res = Kaomoji::KAWAII.sample
  ensure
    Airbag.info 'OpenAI response', input: text, output: res
  end
end
