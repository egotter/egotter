class DirectMessageClient
  def initialize(client)
    @client = client
  end

  def create_direct_message(user_id, text, options = {})
    request = Request.new(@client).init(:json_post, '/1.1/direct_messages/events/new.json', 'message_create', user_id, text)
    request.perform
  end

  def destroy_direct_message(id)
    request = Request.new(@client).init(:delete, "/1.1/direct_messages/events/destroy.json?id=#{id}", nil, nil, nil)
    request.perform
  end

  def direct_message(id)
    request = Request.new(@client).init(:get, "/1.1/direct_messages/events/show.json?id=#{id}", nil, nil, nil)
    request.perform
  end

  def direct_messages(*args, **keyword_args)
    if args.empty?
      direct_messages_received(keyword_args)
    else
      args[0].each do |id|
        direct_message(id)
      end
    end
  end

  def direct_messages_received(options = {})
    direct_messages_events(options).tap do |events|
      events[:events].select!{|event| event[:message_create][:target][:recipient_id].to_i == authenticating_user_id }
    end
  end

  def direct_messages_sent(options = {})
    direct_messages_events(options).tap do |events|
      events[:events].select!{|event| event[:message_create][:sender_id].to_i == authenticating_user_id }
    end
  end

  def direct_messages_events(options = {})
    query = {cursor: nil, count: 20}.merge(options).compact.slice(:cursor, :count).to_query
    request = Request.new(@client).init(:get, "/1.1/direct_messages/events/list.json?#{query}", nil, nil, nil)
    request.perform
  end

  private

  def authenticating_user_id
    @authenticating_user_id ||= @client.user[:id]
  end

  require 'addressable/uri'
  require 'http'
  require 'http/form_data'
  require 'json'
  require 'openssl'
  require 'twitter/error'
  require 'twitter/headers'
  require 'twitter/rate_limit'
  require 'twitter/utils'

  class Request
    include Twitter::Utils
    BASE_URL = 'https://api.twitter.com'.freeze
    attr_accessor :client, :headers, :options, :path, :rate_limit,
                  :request_method, :uri
    alias verb request_method

    def initialize(client)
      @client = client
    end

    def init(request_method, path, type, user_id, text, buttons = [])
      if type == 'message_create'
        message_data = {text: text}
        attach_buttons(message_data, buttons) if buttons.any?
        event = {type: type, message_create: {target: {recipient_id: user_id}, message_data: message_data}}
        options = {event: event}
      else
        options = {}
      end

      @uri = Addressable::URI.parse(BASE_URL + path)
      set_multipart_options!(request_method, options)
      @path = uri.path
      @options = options
      @options_key = {get: :params, json_post: :json, delete: :params}[request_method] || :form

      self
    end

    def attach_buttons(message_data, buttons)
      message_data[:ctas] = [{type: "web_url", label: buttons[0][:label], url: buttons[0][:url]}]
    end

    def perform
      response = http_client.headers(@headers).public_send(@request_method, @uri.to_s, @options_key => @options)
      response_body = response.body.empty? ? '' : symbolize_keys!(response.parse)
      response_headers = response.headers
      fail_or_return_response_body(response.code, response_body, response_headers)
    end

    def merge_multipart_file!(options)
      key = options.delete(:key)
      file = options.delete(:file)

      options[key] = if file.is_a?(StringIO)
                       HTTP::FormData::File.new(file, content_type: 'video/mp4')
                     else
                       HTTP::FormData::File.new(file, filename: File.basename(file), content_type: content_type(File.basename(file)))
                     end
    end

    def set_multipart_options!(request_method, options)
      if %i[multipart_post json_post].include?(request_method)
        merge_multipart_file!(options) if request_method == :multipart_post
        @request_method = :post
        @headers = Twitter::Headers.new(@client, @request_method, @uri).request_headers
      else
        @request_method = request_method
        @headers = Twitter::Headers.new(@client, @request_method, @uri, options).request_headers
      end
    end

    def content_type(basename)
      case basename
      when /\.gif$/i
        'image/gif'
      when /\.jpe?g/i
        'image/jpeg'
      when /\.png$/i
        'image/png'
      else
        'application/octet-stream'
      end
    end

    def fail_or_return_response_body(code, body, headers)
      error = error(code, body, headers)
      raise(error) if error
      @rate_limit = Twitter::RateLimit.new(headers)
      body
    end

    def error(code, body, headers)
      klass = Twitter::Error::ERRORS[code]
      if klass == Twitter::Error::Forbidden
        forbidden_error(body, headers)
      elsif !klass.nil?
        klass.from_response(body, headers)
      end
    end

    def forbidden_error(body, headers)
      error = Twitter::Error::Forbidden.from_response(body, headers)
      klass = Twitter::Error::FORBIDDEN_MESSAGES[error.message]
      if klass
        klass.from_response(body, headers)
      else
        error
      end
    end

    def symbolize_keys!(object)
      if object.is_a?(Array)
        object.each_with_index do |val, index|
          object[index] = symbolize_keys!(val)
        end
      elsif object.is_a?(Hash)
        object.dup.each_key do |key|
          object[key.to_sym] = symbolize_keys!(object.delete(key))
        end
      end
      object
    end

    # @return [HTTP::Client, HTTP]
    def http_client
      client = @client.proxy ? HTTP.via(*proxy) : HTTP
      client = client.timeout(:per_operation, connect: @client.timeouts[:connect], read: @client.timeouts[:read], write: @client.timeouts[:write]) if @client.timeouts
      client
    end

    # Return proxy values as a compacted array
    #
    # @return [Array]
    def proxy
      @client.proxy.values_at(:host, :port, :username, :password).compact
    end
  end
end
