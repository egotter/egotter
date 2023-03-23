module ChatUtil
  def generate_chat(text, options = {})
    res = OpenAiClient.new.chat!(text)
  rescue => e
    SendMessageToSlackWorker.perform_async(:chat_error, {worker: self.class, exception: e, text: text, options: options}.inspect)
    res = Kaomoji::KAWAII.sample
  ensure
    Airbag.info 'OpenAI response', input: text, output: res, worker: self.class
  end
end
