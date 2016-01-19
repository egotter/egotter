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
      logger.warn "#{e.class} - Retry after #{e.rate_limit.reset_in} seconds."
      raise e
    rescue Twitter::Error::ServiceUnavailable => e
      logger.warn "#{e.class} - #{e.message}"
      raise e
    rescue Twitter::Error::InternalServerError => e
      logger.warn "#{e.class} - #{e.message}"
      raise e
    rescue => e
      logger.warn "#{e.class} - #{e.message}"
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

  require 'digest/md5'

  # currently ignore options
  def file_cache_key(method_name, user)
    identifier =
      case
        when user.kind_of?(Integer)
          "id-#{user.to_s}"
        when user.kind_of?(Array) && user.first.kind_of?(Integer)
          "ids-#{Digest::MD5.hexdigest(user.join(','))}"
        when user.kind_of?(Array) && user.first.kind_of?(String)
          "sns-#{Digest::MD5.hexdigest(user.join(','))}"
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

  # encode
  def to_json_according_to_type(obj)
    start_t = Time.now.to_i
    result =
      case
        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::Tweet) # statuses
          JSON.pretty_generate(obj.map { |o| o.attrs })

        when obj.kind_of?(Array) && obj.first.kind_of?(Hash) # friends, followers
          JSON.pretty_generate(obj.map { |o| o.to_hash.slice(*TwitterUser::SAVE_KEYS) })

        when obj.kind_of?(Array) && obj.first.kind_of?(Integer) # friend_ids, follower_ids
          JSON.pretty_generate(obj)

        when obj.kind_of?(Twitter::User) # user
          JSON.pretty_generate(obj.to_hash.slice(*TwitterUser::SAVE_KEYS))

        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::User) # users
          JSON.pretty_generate(obj.map { |o| o.to_hash.slice(*TwitterUser::SAVE_KEYS) })

        when obj === true || obj === false # user?
          obj

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
    obj = str.kind_of?(String) ? JSON.parse(str) : str
    result =
      case
        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::Tweet) # statuses
          obj.map { |o| Hashie::Mash.new(o.attrs) }

        when obj.kind_of?(Array) && obj.first.kind_of?(Hash) # friends, followers
          obj.map { |o| Hashie::Mash.new(o) }

        when obj.kind_of?(Array) && obj.first.kind_of?(Integer) # friend_ids, follower_ids
          obj

        when obj.kind_of?(Hash) # user
          Hashie::Mash.new(obj)

        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::User) # users
          obj.map { |o| Hashie::Mash.new(o.attrs) }

        when obj === true || obj === false # user?
          obj

        else
          raise obj.inspect
      end
    end_t = Time.now.to_i
    logger.debug "#{now} parse_json_according_to_type (#{end_t - start_t}s)"
    result
  end

  def fetch_cache_or_call_api(method_name, args, &block)
    key = namespaced_key(method_name, args[0])
    if cache.exist?(key)
      data = parse_json_according_to_type(cache.read(key))
      logger.debug "#{now} #{method_name} #{key} (cache read)"
      return data
    end

    data = yield

    cache.write(key, to_json_according_to_type(data))
    logger.debug "#{now} #{method_name} #{key} (cache wrote)"

    data
  end

  alias :old_user? :user?
  def user?(*args)
    return old_user? if args.empty?
    fetch_cache_or_call_api(:user?, args) {
      begin
        old_user?(*args)
      rescue Twitter::Error::NotFound => e
        logger.warn "#{e.message} #{args.inspect}"
        raise e
      end
    }
  end

  alias :old_user :user
  def user(*args)
    return old_user if args.empty?
    fetch_cache_or_call_api(:user, args) {
      begin
        old_user(*args)
      rescue Twitter::Error::NotFound => e
        logger.warn "#{e.message} #{args.inspect}"
        raise e
      end
    }
  end
  # memoize :user

  alias :old_friend_ids :friend_ids
  def friend_ids(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:friend_ids, args) {
      options = {count: 5000, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_friend_ids, *args, options)
    }
  end

  alias :old_follower_ids :follower_ids
  def follower_ids(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:follower_ids, args) {
      options = {count: 5000, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_follower_ids, *args, options)
    }
  end

  alias :old_friends :friends
  def friends(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:friends, args) {
      options = {count: 200, include_user_entities: true, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_friends, *args, options)
    }
  end
  # memoize :friends

  def friends_advanced(*args)
    users(friend_ids(*args).map { |id| id.to_i })
  end

  alias :old_followers :followers
  def followers(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:followers, args) {
      options = {count: 200, include_user_entities: true, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_followers, *args, options)
    }
  end
  # memoize :followers

  def followers_advanced(*args)
    users(follower_ids(*args).map { |id| id.to_i })
  end

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

  def friends_and_followers_advanced(*args)
    result = [nil, nil]
    Parallel.each_with_index([args, args], in_threads: 2) do |_args, i|
      if i == 0
        result[0] = friends_advanced(*_args)
      else
        result[1] = followers_advanced(*_args)
      end
    end

    result
  end

  def only_following(me)
    me.friends.to_a - me.followers.to_a
  end

  def only_followed(me)
    me.followers.to_a - me.friends.to_a
  end

  def mutual_friends(me)
    me.friends.to_a & me.followers.to_a
  end
  
  def friends_in_common(me, you)
    me.friends.to_a & you.friends.to_a
  end

  def followers_in_common(me, you)
    me.followers.to_a & you.followers.to_a
  end

  def removing(pre_me, cur_me)
    pre_me.friends.to_a - cur_me.friends.to_a
  end

  def detailed_removing(pre_me, cur_me)
  end

  def removed(pre_me, cur_me)
    pre_me.followers.to_a - cur_me.followers.to_a
  end

  def detailed_removed(pre_me, cur_me)
  end

  # use compact, not use sort and uniq
  alias :old_users :users
  def users(*args)
    options = args.extract_options!
    users_per_workers = args.first.compact.each_slice(100).to_a
    processed_users = []

    Parallel.each_with_index(users_per_workers, in_threads: users_per_workers.size) do |users_per_worker, i|
      _users = fetch_cache_or_call_api(:users, [users_per_worker, options]) {
        old_users(users_per_worker, options)
      }

      result = {i: i, users: _users}
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
  def replying(user)
    screen_names = user_timeline(user).map do |s|
      $1 if s.text =~ /^(?:\.)?@(\w+)( |\W)/ # include statuses starts with .
    end.compact.uniq

    users(screen_names) || []
  end

  # users which specified user is replied
  # when user is login you had better to call mentions_timeline
  def replied(user)
    user = self.user(user).screen_name unless user.kind_of?(String)

    search_result = search('@' + user, count: 100).attrs
    return [] if search_result.blank? || search_result[:statuses].blank?

    uids = search_result[:statuses].map do |s|
      s = Hashie::Mash.new(s)
      s.user.id.to_i if s.text =~ /^(?:\.)?@(\w+)( |\W)/ # include statuses starts with .
    end.compact.uniq

    users(uids) || []
  end

  def clusters_belong_to(text)
    return [] if text.blank?

    exclude_words = JSON.parse(File.read('cluster_bad_words.json'))
    special_words = JSON.parse(File.read('cluster_good_words.json'))

    # クラスタ用の単語の出現回数を記録
    cluster_word_counter =
      special_words.map { |sw| [sw, text.scan(sw)] }
        .delete_if { |item| item[1].empty? }
        .each_with_object(Hash.new(1)) { |item, memo| memo[item[0]] = item[1].size }

    # 同一文字種の繰り返しを見付ける。漢字の繰り返し、ひらがなの繰り返し、カタカナの繰り返し、など
    text.scan(/[一-龠〆ヵヶ々]+|[ぁ-んー～]+|[ァ-ヴー～]+|[ａ-ｚＡ-Ｚ０-９]+|[、。！!？?]+/).

      # 複数回繰り返される文字を除去
      map { |w| w.remove /[？！?!。、ｗ]|(ー{2,})/ }.

      # 文字数の少なすぎる単語、ひらがなだけの単語、除外単語を除去する
      delete_if { |w| w.length <= 1 || (w.length <= 2 && w =~ /^[ぁ-んー～]+$/) || exclude_words.include?(w) }.

      # 出現回数を記録
      each { |w| cluster_word_counter[w] += 1 }

    # 複数個以上見付かった単語のみを残し、出現頻度順にソート
    cluster_words = cluster_word_counter.select { |_, v| v > 3 }.sort_by { |_, v| -v }.to_h.keys

    # 出現回数上位の単語のみを返す
    cluster_words.slice(0, [cluster_words.size, 5].min)
  end

  def clusters_assigned_to

  end
end