module WorkerIdsFetcher
  def fetch_ids(method_name, uid, loop_limit = 10)
    options = {count: 5000, cursor: -1}
    collection = []

    loop_limit.times do
      client = Bot.api_client.twitter
      response = client.send(method_name, uid, options)&.attrs
      break if response.nil?

      collection << response[:ids]

      break if response[:next_cursor] == 0

      options[:cursor] = response[:next_cursor]
    end

    collection.flatten
  end
end
