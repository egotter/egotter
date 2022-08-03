class PermissionLevelClient
  def initialize(client)
    @client = client
  end

  def permission_level
    request = Request.new(@client, :get, '/1.1/account/verify_credentials.json')
    request.perform['X-Access-Level']
  end

  class Request < ::Twitter::REST::Request
    def perform
      http_client.headers(@headers).public_send(@request_method, @uri.to_s, @options_key => @options).headers
    end
  end
end
