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
      query = sort(query, uids)
      fetch(query, uids)
    end

    def sort(query, uids)
      case @value
      when VALUES[0] then query.order_by_field(uids)
      when VALUES[1] then query.order_by_field(uids.reverse)
      when VALUES[2] then query.order(friends_count: :desc)
      when VALUES[3] then query.order(friends_count: :asc)
      when VALUES[4] then query.order(followers_count: :desc)
      when VALUES[5] then query.order(followers_count: :asc)
      when VALUES[6] then query.order(statuses_count: :desc)
      when VALUES[7] then query.order(statuses_count: :asc)
      else raise "Invalid sort value=#{@value}"
      end
    end

    def fetch(query, uids)
      result = []
      offset = 0

      (uids.size / @slice + 1).times do
        if (records = query.offset(offset).limit(@slice).pluck(:uid)).empty?
          break
        else
          result.concat(records)
          offset = result.size
        end
      end

      result
    end
  end
end
