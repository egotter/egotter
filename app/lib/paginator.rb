class Paginator
  def initialize(users)
    @users = users
  end

  def paginate
    users =
        if !@sort_order.default_order? || !@filter.default_filter?
          @users.to_a
        else
          @users
        end

    @sort_order.apply!(users) if @sort_order
    @filter.apply!(users) if @filter

    users = users[@max_sequence, @limit]

    returning_value =
        if users.nil? || users.empty?
          [[], -1]
        else
          [users, @max_sequence + (@limit - 1)]
        end

    Result.new(returning_value[0], returning_value[1], @limit)
  end

  def max_sequence(value)
    @max_sequence = value.to_i
    self
  end

  DEFAULT_LIMIT = 10
  MAX_LIMIT = 10

  def limit(value)
    value = value.to_i
    @limit = (0..MAX_LIMIT).include?(value) ? value : MAX_LIMIT
    self
  end

  def sort_order(value)
    @sort_order = SortOrder.new(value)
    self
  end

  def filter(value)
    @filter = Filter.new(value)
    self
  end

  class Result
    attr_reader :users, :max_sequence, :limit

    def initialize(users, max_sequence, limit)
      @users = users
      @max_sequence = max_sequence
      @limit = limit
    end
  end
end
