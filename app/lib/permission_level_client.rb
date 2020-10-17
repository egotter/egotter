class PermissionLevelClient
  def initialize(client)
    @client = client
  end

  def permission_level
    retries ||= 3
    request = Request.new(@client, :get, '/1.1/account/verify_credentials.json')
    request.perform!
    request.instance_variable_get(:@response_headers)['X-Access-Level']
  rescue => e
    if ServiceStatus.retryable_error?(e)
      if (retries -= 1) > 0
        retry
      else
        raise RetryExhausted.new(e.inspect)
      end
    else
      raise
    end
  end

  class Request < ::Twitter::REST::Request
    def perform!
      response = http_client.headers(@headers).public_send(@request_method, @uri.to_s, @options_key => @options)
      @response_headers = response.headers
    end
  end

  class RetryExhausted < StandardError; end
end
