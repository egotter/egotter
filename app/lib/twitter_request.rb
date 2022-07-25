class TwitterRequest
  def initialize(method)
    @method = method
    @retries = 0
  end

  def perform(&block)
    yield
  rescue => e
    @retries += 1
    handle_exception(e)
    sleep 0.1 * @retries
    retry
  end

  private

  MAX_RETRIES = 3

  def handle_exception(e)
    if ServiceStatus.http_timeout?(e) && @method == :users
      raise ApiClient::StrangeHttpTimeout
    elsif ServiceStatus.retryable_error?(e)
      if @retries > MAX_RETRIES
        raise ApiClient::RetryExhausted.new("#{e.inspect} method=#{@method} retries=#{@retries}")
      else
        Airbag.info "TwitterRequest#perform: #{e.class} is detected and retry method=#{@method}"
      end
    else
      raise e
    end
  end
end