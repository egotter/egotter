class InfluxDBClient
  def initialize
    db_config = Rails.configuration.database_configuration[Rails.env]
    @time_precision = 's'
    # @retention_policy = 'a_year'
    options = {
        username: db_config['username'],
        password: db_config['password'],
        time_precision: @time_precision,
    }
    @client = InfluxDB::Client.new(db_config['database'], options)
  end

  def query(query)
    @client.query(query)
  end

  def read(table, uid, limit:)
    query = "select * from #{table} where uid = '#{uid}' limit #{limit}"
    logger.debug { "InfluxDB: #{query}" }
    result = @client.query(query)[0]
    result ? result['values'] : []
  end

  def write(table, uid, value, time)
    time = time.is_a?(String) ? Time.zone.parse(time) : time
    data = {
        values: {value: value},
        tags: {uid: uid},
        timestamp: time.to_i
    }
    @client.write_point(table, data)
  rescue InfluxDB::Error => e
    if e.message.include?('partial write: points beyond retention policy')
      logger.info e.message
      nil
    else
      raise
    end
  end

  def write_multi(table, values)
    data = values.map do |value|
      time = value.time.is_a?(String) ? Time.zone.parse(value.time) : value.time
      {
          series: table,
          values: {value: value.value},
          tags: {uid: value.uid},
          timestamp: time.to_i
      }
    end
    @client.write_points(data)
  rescue InfluxDB::Error => e
    if e.message.include?('partial write: points beyond retention policy')
      logger.info e.message
      nil
    else
      raise
    end
  end

  def truncate(table)
    query = "delete from #{table}"
    @client.query query
  end

  def logger
    Rails.logger
  end

  class FriendsCount
    attr_reader :uid, :value, :time

    def initialize(uid:, value:, time:)
      @uid = uid.to_i
      @value = value
      @time = time.is_a?(String) ? Time.zone.parse(time) : time
    end

    class << self
      def where(uid:, limit: 100)
        InfluxDBClient.new.read('friends_count', uid, limit: limit).each(&:symbolize_keys!).map { |r| new(r) }
      end

      def create(uid:, value:, time:)
        InfluxDBClient.new.write('friends_count', uid, value, time)
      end

      def import(data)
        InfluxDBClient.new.write_multi('friends_count', data)
      end

      def import_from_twitter_users(uid)
        users = FriendsGroupBuilder.new(uid, limit: 100).users
      end
    end
  end
end
