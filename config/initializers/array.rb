class Array
  def unix_uniq
    return [] if empty?

    result = []
    last = self[0]
    result << last
    self.slice(1, self.size - 1).each do |item|
      if last != item
        result << item
        last = item
      end
    end
    result
  end
end