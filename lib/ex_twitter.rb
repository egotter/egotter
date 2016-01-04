require 'twitter'
require 'memoist'

class ExTwitter < Twitter::REST::Client
  extend Memoist

  def initialize(options = {})
    super
  end

  def logger
    @_logger ||= Rails.logger
  end

  def call_old_method(method_name, *args)
    logger.debug "#{Time.now} #{method_name} #{args.inspect}"
    options = args.extract_options!
    begin
      send(method_name, *args, options)
    rescue Twitter::Error::TooManyRequests => e
      logger.debug "Retry after #{e.rate_limit.reset_in} seconds."
      raise e
    end
  end

  # friends, followers
  def collect_with_cursor(method_name, *args)
    options = args.extract_options!
    last_response = call_old_method(method_name, *args, options).attrs
    return_data = (last_response[:users] || last_response[:ids])

    while (next_cursor = last_response[:next_cursor]) && next_cursor != 0
      options[:cursor] = next_cursor
      last_response = call_old_method(method_name, *args, options).attrs
      return_data += (last_response[:users] || last_response[:ids])
    end

    return_data
  end

  # currently ignore options
  def file_cache_key(method_name, *args)
    identifier =
      case
        when args[0].kind_of?(Fixnum) || args[0].kind_of?(Bignum)
          "id-#{args[0].to_s}"
        when args[0].kind_of?(String)
          "sn-#{args[0]}"
        when args[0].kind_of?(Twitter::User)
          "user-#{args[0].id.to_s}"
        else raise "#{method_name.inspect} #{args.inspect}"
      end

    "#{method_name}_#{identifier}_#{Time.now.strftime('%Y%m%d%H')}.json.gz"
  end

  def file_cache_base
    File.join('tmp', 'file_cache')
  end

  def file_cache_path(method_name, *args)
    File.join(file_cache_base, file_cache_key(method_name, *args))
  end

  def file_cache_exists?(method_name, *args)
    FileUtils.mkdir_p(file_cache_base) unless FileTest.exist?(file_cache_base)
    FileTest.exist?(file_cache_path(method_name, *args))
  end

  def flash_file_cache
    FileUtils.rm_r(file_cache_base)
  end

  def delete_file_cache(method_name, *args)
  end

  # TODO choose necessary data
  def to_json_according_to_type(data)
    if data.kind_of?(Array)
      JSON.pretty_generate(data)
    elsif data.kind_of?(Twitter::User)
      _data = data.to_hash.slice(
        :id,
        :name,
        :screen_name,
        :location,
        :description,
        :url,
        :protected,
        :followers_count,
        :friends_count,
        :listed_count,
        :favourites_count,
        :utc_offset,
        :time_zone,
        :geo_enabled,
        :verified,
        :statuses_count,
        :lang,
        :suspended)
      JSON.pretty_generate(_data)
    else
      raise data.inspect
    end
  end

  def write_file_cache(str, method_name, *args)
    JSON.parse(str) # make sure of json
    FileUtils.mkdir_p(file_cache_base) unless FileTest.exist?(file_cache_base)
    Zlib::GzipWriter.open(file_cache_path(method_name, *args)) { |gz|
      gz.write str
    }
    logger.debug "#{Time.now} #{method_name} #{args.inspect} write_file_cache #{str.size}"
  end

  def read_file_cache(method_name, *args)
    str = ''
    Zlib::GzipReader.open(file_cache_path(method_name, *args)) {|gz|
      str = gz.read
    }
    logger.debug "#{Time.now} #{method_name} #{args.inspect} read_file_cache #{str.size}"
    obj = JSON.parse(str)
    if obj.kind_of?(Array)
      obj.map{|o| o.kind_of?(Hash) ? Hashie::Mash.new(o) : o }
    elsif obj.kind_of?(Hash)
      Hashie::Mash.new(obj)
    else
      obj
    end
  end

  def fetch_cache_or_call_api(method_name, args, &block)
    if file_cache_exists?(method_name, *args)
      data = read_file_cache(method_name, *args)
      logger.debug "#{Time.now} #{method_name} #{args.inspect} (cache read)"
      return data
    end

    data = yield

    write_file_cache(to_json_according_to_type(data), method_name, *args)
    logger.debug "#{Time.now} #{method_name} #{args.inspect} (cache wrote)"

    data
  end

  alias :old_user :user
  def user(*args)
    return old_user if args.empty?
    fetch_cache_or_call_api(:user, args) {
      old_user(args)
    }
  end
  # memoize :user

  alias :old_friends :friends
  def friends(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:friends, args) {
      options = {count: 200, include_user_entities: true, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_friends, *args, options)
    }
  end
  # memoize :friends

  alias :old_followers :followers
  def followers(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:followers, args) {
      options = {count: 200, include_user_entities: true, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_followers, *args, options)
    }
  end
  # memoize :followers

  def friends_and_followers(*args)
    [friends(*args), followers(*args)]
  end
end