class BaseShopClient
  def initialize
    @credentials = Credentials.new('.baseshop/credentials.json')

    if @credentials.client_id.blank?
      raise "#{@credentials.path} is not found"
    end

    if @credentials.authorization_code.blank?
      raise "Get authorization code: #{@credentials.authorization_url}"
    end
  end

  def orders(limit: 3)
    url = 'https://api.thebase.in/1/orders?' + {limit: limit}.to_query
    res = Request.new(:post, url, {Authorization: bearer_auth_header}).perform
    JSON.parse(res)['orders'].map do |order_hash|
      order(order_hash['unique_key'])
    end
  end

  def order(id)
    url = "https://api.thebase.in/1/orders/detail/#{id}?"
    res = Request.new(:post, url, {Authorization: bearer_auth_header}).perform
    Order.new(JSON.parse(res)['order'])
  end

  private

  def bearer_auth_header
    "Bearer #{@credentials.access_token}"
  end

  class Order
    def initialize(hash)
      @data = hash
    end

    def id
      @data['unique_key']
    end

    def full_name
      "#{@data['last_name']} #{@data['first_name']}"
    end

    def email
      @data['mail_address']
    end

    def remark
      @data['remark']
    end

    def method_missing(symbol, *args)
      if @data.has_key?(symbol.to_s)
        @data[symbol.to_s]
      else
        super
      end
    end
  end

  class Request
    def initialize(method, url, headers = {})
      @method = method
      @uri = URI.parse(url)
      @headers = headers
    end

    def perform
      https = Net::HTTP.new(@uri.host, @uri.port)
      https.use_ssl = true
      https.open_timeout = 3
      https.read_timeout = 3
      req = @method == :post ? Net::HTTP::Post.new(@uri) : Net::HTTP::Get.new(@uri)
      req['Content-Type'] = 'application/x-www-form-urlencoded'
      @headers.each do |key, value|
        req[key] = value
      end
      https.start { https.request(req) }.body
    end
  end

  class Credentials
    attr_reader :path

    def initialize(path)
      dir = File.dirname(path)
      Dir.mkdir(dir) unless File.exist?(dir)

      @path = path
      @data = read_file(path)
    end

    def client_id
      @data['client_id']
    end

    def client_secret
      @data['client_secret']
    end

    def authorization_code
      @data['authorization_code']
    end

    def authorization_url
      params = {
          response_type: 'code',
          client_id: client_id,
          redirect_uri: 'https://egotter.thebase.in/',
          scope: 'read_users read_users_mail read_items read_orders',
          state: '',
      }
      'https://api.thebase.in/1/oauth/authorize?' + params.to_query
    end

    def access_token
      update_tokens if @data['access_token'].blank?
      @data['access_token']
    end

    def refresh_token
      update_tokens if @data['refresh_token'].blank?
      @data['refresh_token']
    end

    private

    def update_tokens
      response = JSON.parse(fetch_token)
      @data['access_token'] = response['access_token']
      @data['refresh_token'] = response['refresh_token']
      File.write(@path, @data.to_json)
    end

    def fetch_token
      params = {
          grant_type: 'authorization_code',
          client_id: client_id,
          client_secret: client_secret,
          code: authorization_code,
          redirect_uri: 'https://egotter.thebase.in/',
      }
      url = 'https://api.thebase.in/1/oauth/token?' + params.to_query
      Request.new(:post, url).perform
    end

    def read_file(path)
      if File.exist?(path)
        begin
          JSON.parse(File.read(path))
        rescue => e
          {}
        end
      else
        {}
      end
    end
  end
end
