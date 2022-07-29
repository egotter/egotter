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
      @threshold = 5000
      @threads = 0
      @timeout = 8
    end

    def slice(value)
      @slice = value.to_i
      self
    end

    def threads(value)
      @threads = value.to_i
      self
    end

    def without_cache
      @without_cache = true
      self
    end

    # For test
    def threshold(value)
      @threshold = value.to_i
      self
    end

    def timeout(value)
      @timeout = value.to_i
      self
    end

    def timeout?
      @start_time && @timeout && Time.zone.now - @start_time > @timeout
    end

    def apply(model, uids)
      if @value == VALUES[0]
        return uids
      elsif @value == VALUES[1]
        return uids.reverse
      end

      if @without_cache
        Airbag.info 'TwitterDB::Sort: Sort uids because :without_cache is specified', value: @value
      else
        if uids.size > @threshold
          cache = SortCache.instance

          if cache.exists?(@value, uids)
            Airbag.info 'TwitterDB::Sort: a cache found', value: @value
            return cache.read(@value, uids)
          else
            if (jid = CreateTwitterDBSortCacheWorker.perform_async(@value, uids))
              Airbag.info 'TwitterDB::Sort: Start creating a cache', value: @value, jid: jid
            else
              Airbag.info 'TwitterDB::Sort: Already creating a cache', value: @value
            end
            raise CreatingCache
          end
        else
          Airbag.info 'TwitterDB::Sort: Sort uids because the size of uids is small enough', value: @value
        end
      end

      @start_time = Time.zone.now
      query = model.select(:uid, :friends_count, :followers_count, :statuses_count)
      queries = []

      uids.each_slice(@slice) do |group|
        queries << query.where(uid: group)
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

      result.sort_by(&sorter).map(&:uid)
    ensure
      @start_time = nil
    end

    def work_in_threads(queries, count)
      stopped = false
      result = []

      queries.each_slice(count).map do |group|
        threads = group.map do |query|
          Thread.new(query) do |q|
            ActiveRecord::Base.connection_pool.with_connection do
              q.to_a unless timeout?
            end
          end
        end

        threads.each(&:join)
        cur_result = threads.map(&:value)

        if cur_result.any?(&:nil?)
          stopped = true
          break
        else
          result << cur_result
        end
      end

      if stopped
        raise SafeTimeout.new("timeout=#{@timeout} waited=#{Time.zone.now - @start_time}")
      end

      result.flatten
    end

    def work_direct(queries)
      queries.map do |q|
        raise SafeTimeout.new("timeout=#{@timeout} waited=#{Time.zone.now - @start_time}") if timeout?
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

    # TODO Remove later
    class TimeoutError < StandardError
    end

    class SafeTimeout < StandardError
    end

    class CreatingCache < StandardError
      def initialize
        super('')
      end
    end
  end
end
