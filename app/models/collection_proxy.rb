class CollectionProxy
  attr_accessor :collection, :uid, :sql
  attr_reader :owner

  def initialize(owner)
    @owner = owner
    @collection = []
    @uid = nil
    @sql = nil
  end

  def where(*args)
    raise NotImplementedError
  end

  def size
    raise NotImplementedError
  end

  def to_a
    @collection = ActiveRecord::Base.connection.select_all(@sql).to_a.map { |u| TwitterDB::User.new(u) }
  end

  def each(&block)
    to_a.each &block
  end

  def map(&block)
    to_a.map &block
  end

  def [](*args)
    to_a[*args]
  end

  def slice(*args)
    to_a.slice(*args)
  end
end