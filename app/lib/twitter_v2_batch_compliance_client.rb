class TwitterV2BatchComplianceClient

  def initialize
  end

  def users(ids)
    start_batch('users', ids)
  end

  def tweets(ids)
    start_batch('tweets', ids)
  end

  def job(id)
    fetch_job(id)['data']
  end

  def jobs(type)
    fetch_jobs(type)['data']
  end

  def download(id)
    url = fetch_job(id)['data']['download_url']
    download_result(url)
  end

  def status(id)
    fetch_job(id)['data']['status']
  end

  def wait_until(status, id:, max_attempts: 30, delay: 5)
    max_attempts.times do |n|
      current = fetch_job(id)['data']['status']
      break if current == status
      puts "waiting for #{status} current=#{current} attempts=#{n + 1}"
      sleep delay
    end
  end

  private

  def start_batch(type, ids)
    job = create_job(type)
    if job['detail']
      puts job['detail']
      return
    end

    job = job['data']
    upload_data(job['upload_url'], ids.join("\n"))
    wait_until('complete', id: job['id'])
    download_result(job['download_url'])
  end

  def create_job(type)
    url = 'https://api.twitter.com/2/compliance/jobs'
    headers = {'Authorization' => "Bearer #{bearer_token}", 'Content-Type' => 'application/json'}
    Request.new(url, 'POST', headers, {type: type}).perform
  end

  def upload_data(url, data)
    headers = {'Content-Type' => 'text/plain'}
    Request.new(url, 'PUT', headers, data).perform {}
  end

  def download_result(url)
    Request.new(url, 'GET', [], nil).perform { |res| puts res.inspect; res.split("\n").map { |l| JSON.parse(l) } }
  end

  def fetch_job(id)
    url = "https://api.twitter.com/2/compliance/jobs/#{id}"
    headers = {'Authorization' => "Bearer #{bearer_token}"}
    Request.new(url, 'GET', headers, nil).perform
  end

  def fetch_jobs(type)
    url = "https://api.twitter.com/2/compliance/jobs?type=" + type
    headers = {'Authorization' => "Bearer #{bearer_token}"}
    Request.new(url, 'GET', headers, nil).perform
  end

  def bearer_token
    unless @bearer_token
      client = Twitter::REST::Client.new(consumer_key: ENV['TWITTER_CONSUMER_KEY'], consumer_secret: ENV['TWITTER_CONSUMER_SECRET'])
      client.verify_credentials rescue nil
      @bearer_token = client.bearer_token
    end
    @bearer_token
  end

  class Request
    def initialize(url, method, headers, data)
      @url = url
      @method = method
      @headers = headers
      @data = data
    end

    def perform(&block)
      uri = URI.parse(@url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      req = http_method_class(@method).new(uri)
      @headers.each { |k, v| req[k] = v }
      if @method != 'GET'
        if @data.respond_to?(:to_json)
          req.body = @data.to_json
        else
          req.body = @data
        end
      end
      res = https.start { https.request(req) }
      block_given? ? yield(res.body) : JSON.parse(res.body)
    end

    private

    def http_method_class(value)
      if value == 'POST'
        Net::HTTP::Post
      elsif value == 'PUT'
        Net::HTTP::Put
      elsif value == 'GET'
        Net::HTTP::Get
      else
        raise "Invalid method value=#{value}"
      end
    end
  end
end

