require 'parallel'

class CacheLoader
  def initialize(records, timeout: nil, concurrency: 2, &block)
    @records = records.to_a
    @timeout = timeout
    @concurrency = concurrency
    @block = block
  end

  def load
    @start = Time.zone.now
    q = Queue.new

    Parallel.each(@records, in_threads: @concurrency) do |record|
      raise Parallel::Break if timeout?
      @block.call(record)
      q.push(true)
    end

    unless q.size == @records.size
      raise Timeout
    end
  end

  def timeout?
    @timeout && (Time.zone.now - @start > @timeout)
  end

  class Timeout < StandardError
  end
end
