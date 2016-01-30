require 'active_support'
require 'active_support/cache'

require 'twitter'
require 'memoist'
require 'parallel'



class ExTwitter < Twitter::REST::Client
  extend Memoist

  def initialize(options = {})
    @cache = ActiveSupport::Cache::FileStore.new(File.join('tmp', 'api_cache', Time.now.strftime('%Y%m%d%H')))
    super
  end

  def cache
    @cache
  end

  def logger
    @logger ||= Logger.new('log/ex_twitter.log')
  end

  def call_old_method(method_name, *args)
    options = args.extract_options!
    begin
      start_t = Time.now
      result = send(method_name, *args, options)
      end_t = Time.now
      logger.debug "#{method_name} #{args.inspect} #{options.inspect} (#{end_t - start_t}s)"
      result
    rescue Twitter::Error::TooManyRequests => e
      logger.warn "#{__method__}: call=#{method_name} #{args.inspect} #{e.class} Retry after #{e.rate_limit.reset_in} seconds."
      raise e
    rescue Twitter::Error::ServiceUnavailable => e
      logger.warn "#{__method__}: call=#{method_name} #{args.inspect} #{e.class} #{e.message}"
      raise e
    rescue Twitter::Error::InternalServerError => e
      logger.warn "#{__method__}: call=#{method_name} #{args.inspect} #{e.class} #{e.message}"
      raise e
    rescue Twitter::Error::Forbidden => e
      logger.warn "#{__method__}: call=#{method_name} #{args.inspect} #{e.class} #{e.message}"
      raise e
    rescue Twitter::Error::NotFound => e
      logger.warn "#{__method__}: call=#{method_name} #{args.inspect} #{e.class} #{e.message}"
      raise e
    rescue => e
      logger.warn "#{__method__}: call=#{method_name} #{args.inspect} #{e.class} #{e.message}"
      raise e
    end
  end

  # user_timeline, search
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
    delim = ':'
    identifier =
      case
        when user.kind_of?(Integer)
          "id#{delim}#{user.to_s}"
        when user.kind_of?(Array) && user.first.kind_of?(Integer)
          "ids#{delim}#{Digest::MD5.hexdigest(user.join(','))}"
        when user.kind_of?(Array) && user.first.kind_of?(String)
          "sns#{delim}#{Digest::MD5.hexdigest(user.join(','))}"
        when user.kind_of?(String)
          "sn#{delim}#{user}"
        when user.kind_of?(Twitter::User)
          "user#{delim}#{user.id.to_s}"
        else raise "#{method_name.inspect} #{user.inspect}"
      end

    "#{method_name}#{delim}#{identifier}"
  end

  def namespaced_key(method_name, user)
    file_cache_key(method_name, user)
  end

  # encode
  def encode_json(obj, caller_name, options = {})
    options[:reduce] = true unless options.has_key?(:reduce)
    start_t = Time.now
    result =
      case
        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::Tweet) # statuses
          JSON.pretty_generate(obj.map { |o| o.attrs })

        when obj.kind_of?(Array) && obj.first.kind_of?(Hash) # friends, followers
          data =
            if options[:reduce]
              obj.map { |o| o.to_hash.slice(*TwitterUser::PROFILE_SAVE_KEYS) }
            else
              obj.map { |o| o.to_hash }
            end
          JSON.pretty_generate(data)

        when obj.kind_of?(Array) && obj.first.kind_of?(Integer) # friend_ids, follower_ids
          JSON.pretty_generate(obj)

        when obj.kind_of?(Twitter::User) # user
          JSON.pretty_generate(obj.to_hash.slice(*TwitterUser::PROFILE_SAVE_KEYS))

        when obj.kind_of?(Array) && obj.first.kind_of?(Twitter::User) # users, friends_advanced, followers_advanced
          data =
            if options[:reduce]
              obj.map { |o| o.to_hash.slice(*TwitterUser::PROFILE_SAVE_KEYS) }
            else
              obj.map { |o| o.to_hash }
            end
          JSON.pretty_generate(data)

        when obj === true || obj === false # user?
          obj

        when obj.kind_of?(Array) && obj.empty?
          JSON.pretty_generate(obj)

        else
          raise "#{__method__}: caller=#{caller_name} key=#{options[:key]} obj=#{obj.inspect}"
      end
    end_t = Time.now
    logger.debug "#{__method__}: caller=#{caller_name} key=#{options[:key]} (#{end_t - start_t}s)"
    result
  end

  # decode
  def decode_json(json_str, caller_name, options = {})
    start_t = Time.now
    obj = json_str.kind_of?(String) ? JSON.parse(json_str) : json_str
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

        when obj.kind_of?(Array) && obj.empty?
          obj

        else
          raise "#{__method__}: caller=#{caller_name} key=#{options[:key]} obj=#{obj.inspect}"
      end
    end_t = Time.now
    logger.debug "#{__method__}: caller=#{caller_name} key=#{options[:key]} (#{end_t - start_t}s)"
    result
  end

  def fetch_cache_or_call_api(method_name, user, options = {})
    start_t = Time.now
    key = namespaced_key(method_name, user)
    options.update(key: key)

    if cache.exist?(key)
      data = decode_json(cache.read(key), method_name, options)
      end_t = Time.now
      logger.debug "#{__method__}: caller=#{method_name} key=#{key} (cache read) (#{end_t - start_t}s)"
      return data
    end

    data = yield

    cache.write(key, encode_json(data, method_name, options))
    end_t = Time.now
    logger.debug "#{__method__}: caller=#{method_name} key=#{key} (cache wrote) (#{end_t - start_t}s)"

    data
  end

  alias :old_friendship? :friendship?
  def friendship?(*args)
    options = args.extract_options!
    fetch_cache_or_call_api(:friendship?, args) {
      call_old_method(:old_friendship?, *args, options)
    }
  end

  alias :old_user? :user?
  def user?(*args)
    options = args.extract_options!
    fetch_cache_or_call_api(:user?, args[0]) {
      call_old_method(:old_user?, args[0], options)
    }
  end

  alias :old_user :user
  def user(*args)
    options = args.extract_options!
    fetch_cache_or_call_api(:user, args[0]) {
      call_old_method(:old_user, args[0], options)
    }
  end
  # memoize :user

  alias :old_friend_ids :friend_ids
  def friend_ids(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:friend_ids, args[0]) {
      options = {count: 5000, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_friend_ids, *args, options)
    }
  end

  alias :old_follower_ids :follower_ids
  def follower_ids(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:follower_ids, args[0]) {
      options = {count: 5000, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_follower_ids, *args, options)
    }
  end

  # specify reduce: false to use tweet for inactive_*
  alias :old_friends :friends
  def friends(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:friends, args[0], reduce: false) {
      options = {count: 200, include_user_entities: true, cursor: -1}.merge(args.extract_options!)
      collect_with_cursor(:old_friends, *args, options)
    }
  end
  # memoize :friends

  def friends_advanced(*args)
    users(friend_ids(*args).map { |id| id.to_i })
  end

  # specify reduce: false to use tweet for inactive_*
  alias :old_followers :followers
  def followers(*args)
    args = [user] if args.empty? # need at least one param to use cache
    fetch_cache_or_call_api(:followers, args[0], reduce: false) {
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
  # specify reduce: false to use tweet for inactive_*
  alias :old_users :users
  def users(*args)
    options = args.extract_options!
    users_per_workers = args.first.compact.each_slice(100).to_a
    processed_users = []

    Parallel.each_with_index(users_per_workers, in_threads: [users_per_workers.size, 10].min) do |users_per_worker, i|
      _users = fetch_cache_or_call_api(:users, users_per_worker, reduce: false) {
        call_old_method(:old_users, users_per_worker, options)
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
    fetch_cache_or_call_api(:user_timeline, args[0]) {
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

    search_result = search('@' + user, count: 100).attrs # TODO must use cache
    return [] if search_result.blank? || search_result[:statuses].blank?

    uids = search_result[:statuses].map do |s|
      s = Hashie::Mash.new(s)
      s.user.id.to_i if s.text =~ /^(?:\.)?@(\w+)( |\W)/ # include statuses starts with .
    end.compact.uniq

    users(uids) || []
  end

  def select_inactive_users(users, options = {})
    options[:authorized] = false unless options.has_key?(:authorized)
    two_weeks_ago = 2.weeks.ago.to_i
    users.select do |u|
      if options[:authorized] || !u.protected
        (Time.parse(u.status.created_at).to_i < two_weeks_ago) rescue false
      else
        false
      end
    end
  end

  def inactive_friends(user)
    select_inactive_users(friends_advanced(user))
  end

  def inactive_followers(user)
    select_inactive_users(followers_advanced(user))
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