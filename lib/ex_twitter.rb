require 'active_support'
require 'active_support/cache'

require 'twitter'
require 'memoist'
require 'parallel'



class ExTwitter < Twitter::REST::Client
  extend Memoist

  def initialize(options = {})
    @cache = ActiveSupport::Cache::FileStore.new(File.join('tmp', 'file_cache2'))
    super
  end

  def cache
    @cache
  end

  def logger
    @logger ||= Rails.logger
  end

  def now
    "[#{Time.now}]"
  end

  def call_old_method(method_name, *args)
    logger.debug "#{now} #{method_name} #{args.inspect}"
    options = args.extract_options!
    begin
      send(method_name, *args, options)
    rescue Twitter::Error::TooManyRequests => e
      logger.debug "Retry after #{e.rate_limit.reset_in} seconds."
      raise e
    end
  end

  # usertimeline, search
  def collect_with_max_id(method_name, *args)
    options = args.extract_options!
    last_response = call_old_method(method_name, *args, options)
    return_data = last_response
    call_count = 1

    while last_response.any? && call_count < 3
      options[:max_id] = last_response.last.id
      last_response = call_old_method(method_name, *args, options)
      return_data += last_response
      call_count += 1
    end

    return_data.flatten
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
  def file_cache_key(method_name, user)
    identifier =
      case
        when user.kind_of?(Fixnum) || user[0].kind_of?(Bignum)
          "id-#{user.to_s}"
        when user.kind_of?(String)
          "sn-#{user}"
        when user.kind_of?(Twitter::User)
          "user-#{user.id.to_s}"
        else raise "#{method_name.inspect} #{user.inspect}"
      end

    "#{method_name}_#{identifier}_#{Time.now.strftime('%Y%m%d%H')}"
  end

  def namespaced_key(method_name, user)
    file_cache_key(method_name, user)
  end

  # TODO choose necessary data
  # encode
  def to_json_according_to_type(obj)
    start_t = Time.now.to_i
    result =
      case
        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::Tweet) # statuses
          JSON.pretty_generate(obj.map { |o| o.attrs })
        when obj.kind_of?(Array) && obj.first.kind_of?(Hash) # friends, followers
          JSON.pretty_generate(obj.map { |o| o.to_hash.slice(*TwitterUser::SAVE_KEYS) })
        when obj.kind_of?(Twitter::User) # user
          JSON.pretty_generate(obj.to_hash.slice(*TwitterUser::SAVE_KEYS))
        else
          raise obj.inspect
      end
    end_t = Time.now.to_i
    logger.debug "#{now} to_json_according_to_type (#{end_t - start_t}s)"
    result
  end

  # decode
  def parse_json_according_to_type(str)
    start_t = Time.now.to_i
    obj = JSON.parse(str)
    result =
      case
        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::Tweet) # statuses
          obj.map { |o| Hashie::Mash.new(o.attrs) }
        when obj.kind_of?(Array) && obj.first.kind_of?(Hash) # friends, followers
          obj.map { |o| Hashie::Mash.new(o) }
        when obj.kind_of?(Hash) # user
          Hashie::Mash.new(obj)
        else
          raise obj.inspect
      end
    end_t = Time.now.to_i
    logger.debug "#{now} parse_json_according_to_type (#{end_t - start_t}s)"
    result
  end

  def fetch_cache_or_call_api(method_name, args, &block)
    if cache.exist?(namespaced_key(method_name, args[0]))
      data = parse_json_according_to_type(cache.read(namespaced_key(method_name, args[0])))
      logger.debug "#{now} #{method_name} #{args.inspect} (cache read)"
      return data
    end

    data = yield

    cache.write(namespaced_key(method_name, args[0]), to_json_according_to_type(data))
    logger.debug "#{now} #{method_name} #{args.inspect} (cache wrote)"

    data
  end

  alias :old_user? :user?
  def user?(*args)
    old_user?(*args)
  end

  alias :old_user :user
  def user(*args)
    return old_user if args.empty?
    fetch_cache_or_call_api(:user, args) {
      old_user(*args)
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
    result = [nil, nil]
    Parallel.each_with_index([args, args], in_threads: 2) do |_args, i|
      if i == 0
        result[0] = friends(*_args)
      else
        result[1] = followers(*_args)
      end
    end

    result
  end

  # return users which included both a_users and b_users
  # use hash to reduce computational complexity
  def both_included_users(a_users, b_users)
    return [] if a_users.nil? || b_users.nil?

    a_users_hash = a_users.each_with_object({}).with_index{|(u, memo), i| memo[u.uid.to_s] = i }
    a_users_hash.slice!(*b_users.map{|u| u.uid.to_s })
    a_users_hash.values.sort.map{|i| a_users[i] }
  end

  def mutual_friends(me)
    both_included_users(me.friends, me.followers)
  end

  # return users which included in a_users and not included in b_users
  # use hash to reduce computational complexity
  def excluded_users(a_users, b_users)
    return [] if a_users.nil? || b_users.nil?

    a_users_hash = a_users.each_with_object({}).with_index{|(u, memo), i| memo[u.uid.to_i] = i }
    a_users_hash.except!(*b_users.map{|u| u.uid.to_i })
    a_users_hash.values.sort.map{|i| a_users[i] }
  end

  def removed_friends(pre_me, cur_me)
    excluded_users(pre_me.friends, cur_me.friends)
  end

  def detailed_removed_friends(pre_me, cur_me)
  end

  def removed_followers(pre_me, cur_me)
    excluded_users(pre_me.followers, cur_me.followers)
  end

  def detailed_removed_followers(pre_me, cur_me)
  end

  alias :old_users :users
  def users(*args)
    options = args.extract_options!
    users_per_worker = args.first.each_slice(100).to_a
    processed_users = []

    Parallel.each_with_index(users_per_worker, in_threads: users_per_worker.size) do |_users, i|
      result = {i: i, users: old_users(_users, options)}
      processed_users << result
    end

    processed_users.sort_by{|p| p[:i] }.map{|p| p[:users] }.flatten.compact
  end

  # can't get tweets if specified user is protected
  alias :old_user_timeline :user_timeline
  def user_timeline(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:user_timeline, args) {
      options = {count: 200, include_rts: true}.merge(args.extract_options!)
      collect_with_max_id(:old_user_timeline, *args, options)
    }
  end

  # users which specified user is replying
  # in_reply_to_user_id and in_reply_to_status_id is not used because of distinguishing mentions from replies
  def users_replying(user)
    screen_names = user_timeline(user).map do |s|
      $1 if s.text =~ /^(?:\.)?@(\w+)( |\W)/ # include statuses starts with .
    end.compact.uniq

    users(screen_names) || []
  end

  # users which specified user is replied
  # when user is login you had better to call mentions_timeline
  def users_replied(user)
    user = self.user(user).screen_name unless user.kind_of?(String)

    search_result = search('@' + user, count: 100).attrs
    return [] if search_result.blank? || search_result[:statuses].blank?

    uids = search_result[:statuses].map do |s|
      s = Hashie::Mash.new(s)
      s.user.id.to_i if s.text =~ /^(?:\.)?@(\w+)( |\W)/ # include statuses starts with .
    end.compact.uniq

    users(uids) || []
  end
end