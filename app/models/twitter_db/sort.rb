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
    end

    def slice(value)
      @slice = value.to_i
      self
    end

    def apply(query, uids)
      result = []
      query = query.select(:uid, :friends_count, :followers_count, :statuses_count)
      uids.reverse! if @value == VALUES[1]

      uids.each_slice(@slice) do |partial_uids|
        partial_query = query.where(uid: partial_uids)
        if @value == VALUES[0] || @value == VALUES[1]
          partial_query = partial_query.order_by_field(partial_uids)
        end
        result.concat(partial_query.to_a)
      end

      if @value == VALUES[0] || @value == VALUES[1]
        # Do nothing
      else
        result.sort_by!(&sorter)
      end

      result.map(&:uid)
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
  end
end
