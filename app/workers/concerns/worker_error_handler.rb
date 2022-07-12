module WorkerErrorHandler
  def handle_worker_error(ex, **props)
    Airbag.warn "#{extract_message(ex)}#{extract_hash(props)}", backtrace: ex.backtrace
  end

  private

  def extract_message(ex)
    "#{ex.inspect.truncate(200)}#{" caused by #{ex.inspect.truncate(200)}" if ex.cause}"
  end

  def extract_hash(hash)
    if hash.any?
      ' ' + hash.map { |k, v| "#{k}=#{v}" }.join(' ')
    end
  end
end
