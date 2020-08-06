class Tab
  attr_reader :name, :count, :url

  def initialize(name, count, url)
    @name = name
    @count = count
    @url = url
  end

  def count?
    @count && count > 0
  end
end
