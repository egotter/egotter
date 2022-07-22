module TwitterDB
  class Sort
    VALUES = [
        'desc',
        "asc",
        "friends_desc",
        "friends_asc",
        "followers_desc",
        "followers_asc",
        "statuses_desc",
        "statuses_asc"
    ]

    def initialize(value = nil)
      @value = value && VALUES.include?(value) ? value : VALUES[0]
      @slice = 1000
      @threads = 0
      @timeout = 5
    end

    def slice(value)
      @slice = value.to_i
      self
    end

    def threads(value)
      @threads = value.to_i
      self
    end

    def timeout?
      @start_time && @timeout && Time.zone.now - @start_time > @timeout
    end

    def apply(model, uids)
      @start_time = Time.zone.now
      query = model.select(:uid, :friends_count, :followers_count, :statuses_count)
      queries = []
      uids.reverse! if @value == VALUES[1]

      uids.each_slice(@slice) do |group|
        q = query.where(uid: group)
        if @value == VALUES[0] || @value == VALUES[1]
          q = q.order_by_field(group)
        end
        queries << q
      end

      if @threads > 0
        begin
          result = work_in_threads(queries, @threads)
        rescue ThreadError => e
          Airbag.exception e, threads: @threads, slice: @slice, uids: uids.size
          result = work_direct(queries)
        end
      else
        result = work_direct(queries)
      end

      if @value == VALUES[0] || @value == VALUES[1]
        # Do nothing
      else
        result.sort_by!(&sorter)
      end

      result.map(&:uid)
    ensure
      @start_time = nil
    end

    def work_in_threads(queries, count)
      queries.each_slice(count).map do |group|
        threads = group.map { |query| Thread.new(query) { |q| q.to_a } }
        threads.each(&:join)
        threads.map(&:value)
      end.flatten
    end

    def work_direct(queries)
      queries.map do |q|
        raise TimeoutError.new("timeout=#{@timeout} waited=#{Time.zone.now - @start_time}") if timeout?
        q.to_a
      end.flatten
    end

    def sorter
      case @value
      when VALUES[0] then Proc.new {}
      when VALUES[1] then Proc.new {}
      when VALUES[2] then Proc.new { |record| -record.friends_count }
      when VALUES[3] then Proc.new { |record| record.friends_count }
      when VALUES[4] then Proc.new { |record| -record.followers_count }
      when VALUES[5] then Proc.new { |record| record.followers_count }
      when VALUES[6] then Proc.new { |record| -record.statuses_count }
      when VALUES[7] then Proc.new { |record| record.statuses_count }
      else raise "Invalid sort value=#{@value}"
      end
    end

    class TimeoutError < StandardError
    end
  end
end
