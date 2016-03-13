class LoadAuthUsers
  def run
    json_array = load
    json_array.each do |json|
    end
  end

  def verify_credentials
    processed = Queue.new
    Parallel.each_with_index(clients.slice(0, 10000), in_threads: 100) do |client, i|
      thread_result = (client.verify_credentials rescue nil)
      result = {i: i, result: thread_result}
      processed << result
    end

    processed.size.times.map { processed.pop }.sort_by{|p| p[:i] }.map{|p| p[:result] }.flatten
  end

  def clients
    load.map do |user|
      ApiClient.instance(access_token: user.token, access_token_secret: user.secret)
    end
  end

  def load
    File.read('mongo2.json').split("\n").map do |line|
      Hashie::Mash.new(JSON.parse(line))
    end
  end
end
