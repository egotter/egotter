module TwitterDB
  class Proxy
    def initialize(uids)
      @uids = uids
      @offset = 0
      @slice = 1000
      @sort = Sort.new
    end

    def size
      to_a.size
    end

    # Not used
    def last_uid(value)
      @last_uid = value
      self
    end

    def slice(value)
      @slice = value
      self
    end

    def limit(value)
      @limit = value.to_i
      self
    end

    def offset(value)
      @offset = value.to_i
      self
    end

    def sort(value)
      @sort = Sort.new(value)
      self
    end

    def filter(value)
      @filter = Filter.new(value)
      self
    end

    def to_a
      raise '#limit must be called before calling #to_a' unless @limit

      sorted_uids = @sort.apply(TwitterDB::User.where(uid: @uids), @uids)

      if @last_uid && (index = sorted_uids.index(@last_uid))
        sorted_uids = sorted_uids.slice((index + 1)..-1)
      end

      result = []

      sorted_uids.each_slice(@slice).map do |uids|
        query = TwitterDB::User.where(uid: uids).order_by_field(uids)

        if @filter&.any?
          query = @filter.apply(query)
        end

        result.concat(query.to_a)

        if result.slice(@offset..-1).to_a.size >= @limit
          break
        end
      end

      result.slice(@offset..-1).to_a.take(@limit)
    end

    def result
      {users: to_a, limit: @limit, offset: @offset}
    end
  end
end
