# == Schema Information
#
# Table name: usage_stats
#
#  id                  :integer          not null, primary key
#  uid                 :bigint(8)        not null
#  wday_json           :text(65535)      not null
#  wday_drilldown_json :text(65535)      not null
#  hour_json           :text(65535)      not null
#  hour_drilldown_json :text(65535)      not null
#  usage_time_json     :text(65535)      not null
#  breakdown_json      :text(65535)      not null
#  hashtags_json       :text(65535)      not null
#  mentions_json       :text(65535)      not null
#  tweet_clusters_json :text(65535)      not null
#  tweet_times         :json
#  tweet_clusters      :json
#  words_count         :json
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_usage_stats_on_created_at  (created_at)
#  index_usage_stats_on_uid         (uid) UNIQUE
#

class UsageStat < ApplicationRecord

  DEFAULT_SECONDS = Rails.configuration.x.constants[:usage_stat_recently_created]

  def fresh?(attr = :updated_at, seconds: DEFAULT_SECONDS)
    Time.zone.now - send(attr) < seconds
  end

  %i(wday wday_drilldown hour hour_drilldown usage_time breakdown hashtags mentions).each do |name|
    define_method(name) do
      ivar_name = "@#{name}_cache"
      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      else
        str = send("#{name}_json")
        if str.present?
          instance_variable_set(ivar_name, JSON.parse(str, symbolize_names: true))
        else
          nil
        end
      end
    end
  end

  def friends_stat
    twitter_user = TwitterUser.latest_by(uid: uid)
    friend_uids = twitter_user.friend_uids
    follower_uids = twitter_user.follower_uids
    mutual_friend_uids = twitter_user.mutual_friend_uids

    {
      friends_count:             friend_uids.size,
      followers_count:           follower_uids.size,
      one_sided_friends_count:   twitter_user.one_sided_friendships.size,
      one_sided_followers_count: twitter_user.one_sided_followerships.size,
      mutual_friends_count:      mutual_friend_uids.size,
      one_sided_friends_rate:    twitter_user.one_sided_friends_rate,
      one_sided_followers_rate:  twitter_user.one_sided_followers_rate,
      follow_back_rate:          twitter_user.follow_back_rate,
      followed_back_rate:        mutual_friend_uids.size.to_f / friend_uids.size,
      mutual_friends_rate:       mutual_friend_uids.size.to_f / (friend_uids | follower_uids).size
    }
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{uid}"
    Hash.new(0)
  end

  def tweets_stat
    twitter_user = TwitterUser.latest_by(uid: uid)
    tweets = twitter_user.status_tweets
    tweet_days = tweets.map(&:tweeted_at).map { |time| "#{time.year}/#{time.month}/#{time.day}" }
    tweets_interval =
      if tweets.any?
        (tweets.first.tweeted_at.to_i - tweets.last.tweeted_at.to_i).to_f / tweets.size / 60
      else
        0.0
      end

    {
      statuses_count:         twitter_user.statuses_count,
      statuses_per_day_count: (tweets.size / tweet_days.uniq.size rescue 0.0),
      twitter_days:           (Date.today - twitter_user.account_created_at.to_date).to_i,
      most_active_hour:       most_active_hour,
      most_active_wday:       most_active_wday,
      tweets_interval:        tweets_interval.round(1),
      mentions_count:         tweets.reject(&:retweet?).select(&:mentions?).size,
      media_count:            tweets.reject(&:retweet?).select(&:media?).size,
      links_count:            tweets.reject(&:retweet?).select(&:urls?).size,
      hashtags_count:         tweets.reject(&:retweet?).select(&:hashtags?).size,
      locations_count:        tweets.reject(&:retweet?).select(&:location?).size,
      wday:                   chart_data(:wday),
      wday_drilldown:         chart_data(:wday_drilldown),
      hour:                   chart_data(:hour),
      hour_drilldown:         chart_data(:hour_drilldown),
      breakdown:              breakdown
    }
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{uid}"
    Hash.new(0)
  end

  def most_active_hour
    max_value = chart_data(:hour).map { |obj| obj[:y] }.max
    chart_data(:hour).find { |obj| obj[:y] == max_value }.try(:fetch, :name, nil)
  end

  def most_active_wday
    max_value = chart_data(:wday).map { |obj| obj[:y] }.max
    chart_data(:wday).find { |obj| obj[:y] == max_value }.try(:fetch, :name, nil)
  end

  def mention_uids
    mentions.keys.map(&:to_s).map(&:to_i)
  end

  def chart_data(name)
    if tweet_times
      times = tweet_times.map { |t| Time.zone.at(t) }

      case name
      when :wday
        Misc.usage_stats_wday_series_data(times)
      when :wday_drilldown
        Misc.usage_stats_wday_drilldown_series(times)
      when :hour
        Misc.usage_stats_hour_series_data(times)
      when :hour_drilldown
        Misc.usage_stats_hour_drilldown_series(times)
      when :usage_time
        Misc.twitter_addiction_series(times)
      else
        raise "Invalid name value=#{name}"
      end
    else
      send(name)
    end
  end

  def sorted_tweet_clusters
    tweet_clusters&.sort_by { |_, c| -c }&.to_h
  end

  def self.builder(uid)
    Builder.new(uid)
  end

  class Builder
    attr_reader :uid

    def initialize(uid)
      @uid = uid.to_i
    end

    def build
      @statuses = TwitterUser.latest_by(uid: @uid)&.status_tweets if @statuses.blank?
      return if @statuses.blank?

      times = @statuses.take(400).map(&:tweeted_at).select { |t| t > 1.year.ago }
      text = @statuses.take(400).map(&:text).join(' ').gsub(/[\n']/, ' ')

      UsageStat.find_or_initialize_by(uid: uid).tap do |stat|
        stat.assign_attributes(
            wday_json:           '',
            wday_drilldown_json: '',
            hour_json:           '',
            hour_drilldown_json: '',
            usage_time_json:     '',
            breakdown_json:      extract_breakdown(@statuses).to_json,
            hashtags_json:       extract_hashtags(@statuses).to_json,
            mentions_json:       extract_mentions(@statuses).to_json,
            tweet_clusters_json: '',
            tweet_times:         times.map(&:to_i),
            tweet_clusters:      TweetCluster.new.count_words(text),
            words_count:         WordCloud.new.count_words(text),
            )
      end
    end

    def statuses(statuses)
      @statuses = statuses
      self
    end

    private

    def extract_breakdown(statuses)
      tweets = statuses.to_a
      tweets_size = tweets.size
      if tweets_size == 0
        {
          mentions: 0.0,
          media:    0.0,
          urls:     0.0,
          hashtags: 0.0,
          location: 0.0
        }
      else
        {
          mentions: tweets.select(&:mentions?).size.to_f / tweets_size,
          media:    tweets.select(&:media?).size.to_f    / tweets_size,
          urls:     tweets.select(&:urls?).size.to_f     / tweets_size,
          hashtags: tweets.select(&:hashtags?).size.to_f / tweets_size,
          location: tweets.select(&:location?).size.to_f / tweets_size
        }
      end
    end

    def extract_hashtags(statuses)
      statuses.reject(&:retweet?).select(&:hashtags?).map(&:hashtags).flatten.
        map { |h| "##{h}" }.each_with_object(Hash.new(0)) { |hashtag, memo| memo[hashtag] += 1 }.
        sort_by { |h, c| [-c, -h.size] }.to_h
    end

    def extract_mentions(statuses)
      statuses.reject(&:retweet?).select(&:mentions?).map(&:mention_uids).flatten.
        each_with_object(Hash.new(0)) { |uid, memo| memo[uid.to_s.to_sym] += 1 }.
        sort_by { |u, c| -c }.to_h
    end
  end

  module Misc
    module_function

    EVERY_DAY = (0..6)
    WDAY_COUNT = EVERY_DAY.map { |n| [n, 0] }.to_h
    WDAY_NIL_COUNT = EVERY_DAY.map { |n| [n, nil] }.to_h

    EVERY_HOUR = (0..23)
    HOUR_COUNT = EVERY_HOUR.map { |n| [n, 0] }.to_h
    HOUR_NIL_COUNT = EVERY_HOUR.map { |n| [n, nil] }.to_h

    def count_wday(times)
      times.each_with_object(WDAY_COUNT.dup) { |time, memo| memo[time.wday] += 1 }
    end

    def count_hour(times)
      times.each_with_object(HOUR_COUNT.dup) { |time, memo| memo[time.hour] += 1 }
    end

    # [
    #   {:name=>"Sun", :y=>111, :drilldown=>"Sun"},
    #   {:name=>"Mon", :y=>95,  :drilldown=>"Mon"},
    #   {:name=>"Tue", :y=>72,  :drilldown=>"Tue"},
    #   {:name=>"Wed", :y=>70,  :drilldown=>"Wed"},
    #   {:name=>"Thu", :y=>73,  :drilldown=>"Thu"},
    #   {:name=>"Fri", :y=>81,  :drilldown=>"Fri"},
    #   {:name=>"Sat", :y=>90,  :drilldown=>"Sat"}
    # ]
    def usage_stats_wday_series_data(times, day_names: I18n.t('date.abbr_day_names'))
      count_wday(times).map do |wday, count|
        {name: day_names[wday], y: count, drilldown: day_names[wday]}
      end
    end

    # [
    #   {
    #     :name=>"Sun",
    #     :id=>"Sun",
    #     :data=> [ ["0", 7], ["1", 12], ... , ["22", 10], ["23", 12] ]
    #   },
    #   ...
    #   {
    #     :name=>"Mon",
    #     :id=>"Mon",
    #     :data=> [ ["0", 22], ["1", 11], ... , ["22", 9], ["23", 14] ]
    #   }
    def usage_stats_wday_drilldown_series(times, day_names: I18n.t('date.abbr_day_names'))
      counts =
          EVERY_DAY.each_with_object(WDAY_NIL_COUNT.dup) do |wday, memo|
            memo[wday] = count_hour(times.select { |t| t.wday == wday })
          end

      counts.map { |wday, hour_count| [day_names[wday], hour_count] }.map do |wday, hour_count|
        {name: wday, id: wday, data: hour_count.map { |hour, count| [hour.to_s, count] }}
      end
    end

    # [
    #   {:name=>"0", :y=>66, :drilldown=>"0"},
    #   {:name=>"1", :y=>47, :drilldown=>"1"},
    #   ...
    #   {:name=>"22", :y=>73, :drilldown=>"22"},
    #   {:name=>"23", :y=>87, :drilldown=>"23"}
    # ]
    def usage_stats_hour_series_data(times)
      colors = {
          morning: 'rgba(220, 50, 47, 1.0)',
          afternoon: 'rgba(220, 50, 47, 1.0)',
          night: 'rgba(220, 50, 47, 1.0)',
          else: 'rgba(108, 113, 196, 1.0)',
      }
      count_hour(times).map do |hour, count|
        color =
            if 7 <= hour && hour <= 9
              colors[:morning]
            elsif 11 <= hour && hour <= 13
              colors[:afternoon]
            elsif 20 <= hour && hour <= 22
              colors[:night]
            else
              colors[:else]
            end
        {name: hour.to_s, y: count, color: color, drilldown: hour.to_s}
      end
    end

    # [
    #   {:name=>"0", :id=>"0", :data=>[["Sun", 7], ["Mon", 22], ["Tue", 8], ["Wed", 9], ["Thu", 9], ["Fri", 6], ["Sat", 5]]},
    #   {:name=>"1", :id=>"1", :data=>[["Sun", 12], ["Mon", 11], ["Tue", 5], ["Wed", 5], ["Thu", 0], ["Fri", 8], ["Sat", 6]]},
    #   ...
    # ]
    def usage_stats_hour_drilldown_series(times, day_names: I18n.t('date.abbr_day_names'))
      counts =
          EVERY_HOUR.each_with_object(HOUR_NIL_COUNT.dup) do |hour, memo|
            memo[hour] = count_wday(times.select { |t| t.hour == hour })
          end

      counts.map do |hour, wday_count|
        {name: hour.to_s, id: hour.to_s, data: wday_count.map { |wday, count| [day_names[wday], count] }}
      end
    end

    # [
    #   {:name=>"Sun", :y=>14.778310502283107},
    #   {:name=>"Mon", :y=>12.273439878234399},
    #   {:name=>"Tue", :y=>10.110578386605784},
    #   {:name=>"Wed", :y=>9.843683409436835},
    #   {:name=>"Thu", :y=>10.547945205479452},
    #   {:name=>"Fri", :y=>10.61773211567732},
    #   {:name=>"Sat", :y=>12.115753424657534}
    # ]
    def twitter_addiction_series(times, day_names: I18n.t('date.abbr_day_names'))
      max_duration = 5.minutes
      wday_count =
          EVERY_DAY.each_with_object(WDAY_NIL_COUNT.dup) do |wday, memo|
            target_times = times.select { |t| t.wday == wday }
            memo[wday] =
                if target_times.empty?
                  nil
                else
                  target_times.each_cons(2).map { |newer, older| (newer - older) < max_duration ? newer - older : max_duration }.sum
                end
          end
      days = times.map { |t| t.to_date.to_s(:long) }.uniq.size
      weeks = [days / 7.0, 1.0].max
      wday_count.map do |wday, seconds|
        {name: day_names[wday], y: (seconds.nil? ? nil : seconds / weeks / 60)}
      end
    end
  end

  class TweetCluster
    def initialize
      @allow_list = ['( ´Д`)', '(>_<)', '(^-^)', '(^q^)', '(^人^)', '(´;ω;｀)', '(´ω｀)', '(´Д` )', '(´∀｀)', '(´・ω・`)', '(ΦωΦ)', '(ノД`)', '(｡-_-｡)', '(ﾟ∀ﾟ)', '3DS', 'AKB', 'AZU', 'Apple', 'CSS', 'C++', 'Cassandra', 'C言語', 'C＋＋', 'DJ', 'Disco', 'EXILE', 'Echofone', 'F1', 'FC岐阜', 'FC東京', 'FaceBook', 'GALAPAGOS', 'Galaxy', 'HASKEL', 'HIP HOP', 'Hip-Hop', 'IE6', 'IKEA', 'JAXA', 'JIN', 'JK', 'JUMP', 'JavaScript', 'KARA', 'LISP', 'Linux', 'MBA', 'Microsoft', 'NASA', 'NBA', 'NHK', 'NMB', 'NMB', 'OCaml', 'OOO', 'Oracle', 'PHP', 'PSP', 'Panasonic', 'Perfume', 'Perl', 'Python', 'R&B', 'Ruby', 'SCHEME', 'SDN', 'SKE', 'SMAP', 'SMAP', 'SPEC', 'Scala', 'Skype', 'SoftBank', 'TBS', 'TOKIO', 'TRPG', 'Techno', 'UFO', 'UMA', 'VIPPER', 'VJ', 'WBS', 'WILLCOM', 'Wi-Fi', 'Wii', 'XBOX', 'Xperia', 'YUI', 'ZEP', 'ZONE', 'amazon', 'android', 'ardino', 'bot', 'censored', 'chrome', 'cisco', 'clasicc', 'disって', 'docomo', 'domune', 'experia', 'firefox', 'google', 'house', 'iPad', 'iPhone', 'index', 'java', 'jazz', 'kindle', 'ktkr', 'kwsk', 'mixi', 'orz', 'smap', 'soul', 'tokio', 'w-inds', 'wiki', 'wktk', 'yahoo', 'ʕ•̫͡•ʔ', '∞', '⊂((・x・))⊃', 'あの花', 'おわコン', 'お好み焼き', 'お尻', 'かつ丼', 'このまま眠りつづけて死ぬ', 'こんなの絶対おかしいよ', 'さや侍', 'たい焼き', 'たこ焼き', 'つけ麺', 'と聞いて', 'のび太', 'はてブ', 'まどか☆マギカ', 'まどかマギカ', 'みそ汁', 'むぎ', 'もふ', 'ももクロ', 'やや', 'アイコンの気持ち', 'アゴ', 'イカ娘', 'エモ', 'ガリガリ君', 'キキ', 'キュゥべえ', 'キュウべえ', 'クズ', 'サガ', 'サレ', 'ジジ', 'スネ夫', 'ゼル', 'ゾロ', 'ティロ・フィナーレ', 'テレ東', 'ドヤ', 'ドラえもん', 'ドラミちゃん', 'ニコ動', 'ニコ生', 'ネギ', 'ネギま', 'ネタ', 'バグ', 'フジ', 'ブン太', 'マンＵ', 'ムー様', 'モフ', 'ヨガ', 'ラブ人間', 'ルカ子', '三重', '中井', '中日', '中継', '主婦', '主婦', '乙夜', '二郎', '交渉', '京介', '京急', '京極', '京都', '人狼', '仏像', '代数', '伊達', '佐賀', '佳林', '便所', '信長', '修造', '俳句', '俺の嫁', '俺妹', '倉間', '倫理', '偏向', '健全', '元就', '兄弟', '兄貴', '先生', '先輩', '光速', '全裸', '兵庫', '兼光', '円堂', '円風', '写真', '冥途', '凌統', '分析', '初音ミク', '刹那', '刺身', '刺身', '剛毛', '副垢', '助手', '動物', '勝呂', '募金', '化学', '医者', '十代', '千早', '千葉', '半熟', '卓球', '南極', '南沢', '参戦', '司法', '吃驚', '吉武', '吉良', '吉野', '名言', '吹雪', '和希', '和希', '和物', '哲学', '唯', '営業', '回文', '団子', '囲碁', '土門', '地獄', '基山', '埼玉', '声優', '声優', '変態', '外科', '外貨', '夢美', '大丈夫だ', '大分', '大宮', '大正', '大石', '大阪', '天使', '天則', '天国', '天子', '天空', '奈々', '奈良', '女医', '女王', '妄想', '姉妹', '姉御', '姐御', '姐御', '姜維', '婚活', '嫁', '子ども', '子犬', '宇宙', '定期', '実況', '宮地', '宮城', '宮崎', '家康', '富山', '寝落ち', '寧々', '将臣', '小売', '小室', '小魚', '小鳥', '少佐', '就活', '尾浜', '山口', '山形', '山梨', '岐阜', '岡山', '岡崎', '岩手', '島根', '嵐', '川崎', '工場', '工学', '巨乳', '巨人', '布団', '師匠', '平塚', '平沢', '幸村', '幼女', '幾何', '広告', '広島', '廃人', '廉造', '廣瀬', '建築', '弾幕', '影華', '後藤', '徳島', '徹夜', '心理', '忍たま', '忍者', '志摩', '快斗', '恍惚', '恐ろしい子', '悪人', '悪化', '悪魔', '意識高い', '愛媛', '愛媛FC', '愛生', '愛知', '慶應', '憂', '戦国', '手塚', '投資', '折紙', '抹茶', '拓南', '捗るぞ', '改変', '政宗', '政治', '教育', '散歩', '数学', '数学ガール', '数独', '文学', '文系', '斎賀', '料理', '新一', '新宿', '新潟', '旅行', '日テレ', '日ハム', '日常', '旦那', '早苗', '昆虫', '明治', '星ちゃん', '星占い', '星座', '映司', '映画', '春川', '昭和', '時計', '暇人', '暗殺', '有意義だったか', '本田', '札幌', '朱悠', '東京', '東南アジア', '東大', '東急', '東方', '東横', '林檎', '柏', '柔造', '栃木', '梓', '森ガール', '森田', '楽器', '楽天', '横丁', '横浜', '横浜FC', '次長', '正宗', '歯ブラシ', '歴史', '死期が近い', '残業', '段ボール', '民謡', '気象', '水戸', '水泳', '沖田', '沖縄', '法学', '法律', '流通', '浣腸', '浦和', '海獣', '海苔', '深夜', '深海', '清水', '渡部', '温泉', '温泉', '湘南', '滋賀', '演歌', '漢字', '漫画', '澪', '激辛', '瀧', '火狐', '炎上', '為替', '無双', '無線LAN', '無縁', '無視', '焼きそば', '照美', '熊本', '燐たん', '燻製', '燻製', '爆発しろ', '爆発しろ', '片桐', '牛丼', '牛乳', '牛乳', '牛角', '物理', '物理', '狂人', '狂人', '狐', '狸', '猫', '王将', '玩具', '理系', '環境', '生物', '田淵', '甲府', '甲斐', '疲労', '痛快', '痛車', '登山', '白目', '白石', '百合', '眉毛', '真山', '真田', '着物', '短歌', '石川', '研究', '確立', '磐田', '社畜', '社長', '神戸', '神曲', '神楽', '神話', '神話', '神速', '禅', '福井', '福山', '福岡', '福島', '秀吉', '秋田', '税金', '空気', '立綱', '竜馬', '筋トレ', '筋少', '筋肉', '節水', '節電', '簿記', '米英', '粘菌', '素材', '紳士', '経営', '経済', '結界', '統計', '絵本', '綱立', '線形', '編物', '編集', '練乳', '署名', '羅刹', '美味しんぼ', '美琴', '群馬', '翔ちゃん', '耳かき', '聖也', '聖川', '職人', '職質', '股間', '育児', '胸熱', '腕毛', '腰痛', '膀胱', '自作', '自炊', '至福', '般若', '花いろ', '花とゆめ', '花承', '花承', '英語', '茨城', '茶々', '草津', '荒ぶる', '萌え', '萌乃', '萎え', '落語', '蓮二', '薔薇', '薮', '藤内', '藤原', '虎丸', '虎兎', '虎徹', '虎豪', '虫', '虫歯', '裏山', '西島', '西川', '西東', '西部', '西野カナ', '見てる', '規制', '解脱', '言語', '証明', '詐欺', '詩緒', '読書', '課長', '課題', '論文', '貧乳', '跡部', '踊る', '軍師', '軍曹', '農業', '通信', '通販', '速報', '速読', '速読', '進撃の', '遅延', '遊戯', '遊星', '遊馬', '道徳', '邦衛', '郁人', '部長', '郭淮', '酵素', '野口', '野球', '野菜', '金妻', '金融', '金造', '金髪', '鈴泉', '鉄ヲタ', '鉄子', '鉄道', '鉄道', '鉢くく', '鉢雷', '銀さん', '銀河', '銀玉', '銀魂', '鎖骨', '長崎', '長野', '開発', '閑子', '関俊', '闇さん', '阪急', '阪神', '隊長', '雅楽', '離散', '雪歩', '雪燐', '雪男', '雲雀', '雷魚', '電卓', '電車', '霊圧', '青じそ', '青エク', '青プ', '青学', '青森', '静岡', '静雄', '非コミュ', '非モテ', '音ゲー', '音楽', '音速', '音速ライン', '音響', '須田', '風丸', '食器', '飲食', '餃子', '香川', '高専', '高知', '鬼帝', '鬼道', '魂フェス', '魔まマ', '魔術', '鳥取', '鳥栖', '鷹の爪', '鹿島', '麻雀', '（^人^）', '（ω）', '（゜Д゜）', '＼(^o^)／', 'ｵﾜﾀ', 'ｶﾞﾀｯ', 'ｶﾞﾗｯ', 'ｷﾘｯ', 'ｺﾞｸﾘ', 'ﾄﾞﾔ', 'ﾄﾞﾝｯ', 'ﾋﾞｸｯ', '京成', 'お絵描き', '真斗', '正臣', '毒島']
      deny_list = ['C＋', 'あいつの', 'あたしが', 'あたしって', 'あたしに', 'あたしは', 'あたしも', 'あたしを', 'あった', 'あったら', 'あとは', 'あなたが', 'あなたがたが', 'あなたがたは', 'あなたと', 'あなたに', 'あなたの', 'あなたは', 'あなたを', 'ありがと', 'ありがとう', 'ありがとうございました', 'ありがとうございます', 'あります', 'ありますか', 'ありません', 'あるいは', 'あるのでしたら', 'あれ', 'あれだ', 'あれは', 'あんのか', 'あんま', 'あんまり', 'いいたいします', 'いいたします', 'いいな', 'いかな', 'いかなる', 'いから', 'いけど', 'いします', 'いしますです', 'いしますね', 'いしますー', 'いしまーす', 'いすんな', 'いすんなと', 'いたい', 'いたいこと', 'いたかった', 'いたかな', 'いたくて', 'いたなぁ', 'いたので', 'いたよ', 'いたら', 'いっきり', 'いってくる', 'いつける', 'いつも', 'いつもりで', 'いてあった', 'いてある', 'いてあるけど', 'いていきませんか', 'いている', 'いているのは', 'いてえな', 'いてた', 'いてない', 'いてます', 'いてみなさい', 'いてみませんか', 'いてる', 'いです', 'いですが', 'いですね', 'いですよ', 'いですよね', 'いとか', 'いなぁ', 'いなあ', 'いなく', 'いなる', 'いなー', 'いのか', 'いのかい', 'いのが', 'いので', 'いのに', 'いのは', 'いました', 'います', 'いますか', 'いますが', 'いますがよろしくお', 'いますぐ', 'いようです', 'いよね', 'いるなら', 'いれときます', 'いんです', 'うかな', 'うから', 'うけど', 'うございました', 'うございます', 'うじゃん', 'うだけ', 'うちの', 'うちは', 'うちも', 'うなや', 'うなよ', 'うのかな', 'うのが', 'うのだ', 'うので', 'うのです', 'うのは', 'うのやなさい', 'うべき', 'うよっ', 'うんだ', 'うんだけど', 'えがある', 'えきらない', 'えしなくちゃ', 'えたいよ', 'えたから', 'えたら', 'えてください', 'えてよね', 'えない', 'えないところに', 'えねえ', 'えました', 'えましたし', 'えます', 'えますか', 'えもん', 'えよう', 'えよな', 'えられない', 'えるかな', 'えるから', 'えると', 'えるね', 'えるように', 'えるんだ', 'おかえり', 'おかえりなさい', 'おかえりなさいませ', 'おかえりなさいー', 'おかえりなさい～', 'おかえりなさ～い', 'おかえりなさ～い', 'おかえりー', 'おかえり～', 'おかえり～', 'おかしいよ', 'おっと', 'おつあり', 'おつかり', 'おつかれさまです', 'おつかれさまー', 'おはよう', 'おはようございます', 'おはようございますー', 'おはようー', 'おはよう～', 'おはよー', 'おはよーう', 'おはよーございます', 'おめでとう', 'おめでとうございます', 'おやすみ', 'おやすみなさい', 'おやすみなさいませ', 'おやすみなさいー', 'おやすみなさい～', 'おやすみなさーい', 'おやすみなさ～い', 'おやすみなさ～い', 'おやすみー', 'おやすみ～', 'おやすみ～', 'おやすみ～', 'おれは', 'おわったー', 'かいの', 'かいます', 'かけてきます', 'かしい', 'かすぎて', 'かせたい', 'かった', 'かったです', 'かったので', 'かったのに', 'かったら', 'かっていない', 'かっている', 'かってない', 'かってる', 'かなぁ', 'かない', 'かないで', 'かなくなったら', 'かなければ', 'かなり', 'かなりの', 'かぬなら', 'からただいま', 'からない', 'からの', 'からん', 'かります', 'かれます', 'かれると', 'があがった', 'があったら', 'があって', 'があってだな', 'があり', 'がありましたら', 'があります', 'がある', 'があるとよく', 'があるの', 'があるのですか', 'があれば', 'がいい', 'がいた', 'がいたら', 'がいたり', 'がいて', 'がいなくて', 'がいる', 'がうまい', 'がおらんのでしょう', 'がかわいそうで', 'がきてた', 'がきました', 'がきれい', 'がくり', 'がくる', 'がしたいです', 'がして', 'がしてきた', 'がします', 'がすきだ', 'がすぐ', 'がすごい', 'がすごく', 'がする', 'がするけど', 'がずっと', 'がたまらない', 'がたまりません', 'がたまる', 'がだいすき', 'がって', 'がってろ', 'がついている', 'がつかないんだけど', 'がつかぬ', 'ができる', 'がとても', 'がなぁ', 'がない', 'がないと', 'がないのが', 'がないので', 'がはじまったね', 'がまだ', 'がやばい', 'がわかって', 'がわかる', 'がんばれ', 'きしめたい', 'きしめたりすると', 'きしめる', 'きすぎて', 'きそば', 'きたい', 'きたいけど', 'きたいな', 'きたかった', 'きたら', 'きだから', 'きだけど', 'きだぜ', 'きだった', 'きだったんです', 'きだな', 'きだよ', 'きっと', 'きつづけて', 'きてますか', 'きです', 'きですね', 'きながら', 'きなものが', 'きなものは', 'きなんだ', 'きなんだけど', 'きには', 'きはそちらの', 'きました', 'きましょう', 'きます', 'きませんか', 'ぎたい', 'くした', 'くしたって', 'くしてしまったり', 'くために', 'ください', 'くださいまし', 'くといいでしょう', 'くない', 'くなった', 'くなってきた', 'くなり', 'くなりたい', 'くなりました', 'くなりましたが', 'くなる', 'くなれ', 'くなれよ', 'くにいる', 'くのが', 'くのは', 'くのもいいけど', 'くよの', 'くらい', 'くれると', 'くわからん', 'くんが', 'くんと', 'くんの', 'くんは', 'くんも', 'くんを', 'ぐらい', 'けください', 'けたのです', 'けたら', 'けだよ', 'けだよ', 'けていく', 'けている', 'けてくれればいつでも', 'けてます', 'けとか', 'けない', 'けました', 'ければ', 'げてください', 'げてぐださい', 'げない', 'げなきゃ', 'げました', 'げます', 'げれる', 'こういう', 'こうよ', 'こえます', 'ここには', 'こされた', 'こしてくれます', 'こそは', 'こちらこそ', 'このまま', 'これから', 'これが', 'これだけ', 'これだけで', 'これで', 'これは', 'これを', 'こんあんは', 'こんな', 'こんなに', 'こんなの', 'こんなので', 'こんにちは', 'ごきげんよう', 'ごきげんよう～', 'ございます', 'ごした', 'ごしだと', 'ごそうぜ', 'ごめんなさい', 'さいな', 'さいね', 'さいよ', 'さくな', 'さすが', 'さすがに', 'させた', 'させて', 'させていただきました', 'させていただきましたので', 'させる', 'さっき', 'さっきから', 'さった', 'さてと', 'さない', 'さびは', 'された', 'されたい', 'されたときの', 'されたら', 'されたらあなたは', 'されたり', 'されて', 'されていません', 'されている', 'されてないので', 'されてます', 'されてる', 'されなかったら', 'されました', 'されます', 'されますので', 'される', 'されろ', 'さんお', 'さんから', 'さんが', 'さんだった', 'さんでした', 'さんでしたか', 'さんと', 'さんとすれ', 'さんとの', 'さんどうぞ', 'さんに', 'さんの', 'さんのあだ', 'さんのお', 'さんは', 'さんへ', 'さんへの', 'さんも', 'さんや', 'さんを', 'しいです', 'しいでも', 'しいと', 'しいなぁ', 'しいなって', 'しいね', 'しいのか', 'しいものです', 'しいよ', 'しいようです', 'しいような', 'しいように', 'しいわ', 'しかけ', 'しかけました', 'しかし', 'しかしない', 'しかった', 'しかったです', 'しかない', 'しかも', 'しくお', 'しください', 'しくて', 'しくは', 'しくはこちら', 'しくも', 'しくも', 'しすぎて', 'しそう', 'しそうに', 'した', 'したい', 'したから', 'したことある', 'したこの', 'したった', 'したって', 'したと', 'したのか', 'したので', 'したよ', 'したよー', 'したら', 'したり', 'したんですの', 'していた', 'していました', 'しています', 'していません', 'している', 'しておいた', 'してから', 'してきた', 'してください', 'してくださいな', 'してくださいませ', 'してくれたら', 'してくれよ', 'してくれるんだな', 'してしまっても', 'してた', 'してたら', 'してっと', 'してて', 'してても', 'してね', 'してました', 'してます', 'してみた', 'してみよう', 'しても', 'してやった', 'してやってください', 'してやろう', 'してよ', 'してる', 'してるのか', 'してるよ', 'しである', 'しない', 'しないと', 'しながら', 'しにかわりまして', 'しになる', 'しぶりに', 'しぶりの', 'しました', 'しましょう', 'します', 'しますよ', 'しませて', 'しませんか', 'しませんが', 'しませんように', 'しみです', 'しょう', 'しょうがないね', 'しよう', 'しようぜ', 'しようぜー', 'しようと', 'しようとしたら', 'しようよ', 'しろよ', 'しをみ', 'じです', 'じですね', 'じましたら', 'じます', 'じゃあ', 'じゃない', 'じゃないから', 'じゃないし', 'じゃないの', 'じゃないんだ', 'じゃなくて', 'じゃね', 'じゃねぇ', 'じゃねえ', 'じゃねえよ', 'じゃん', 'じれば', 'すいた', 'すいません', 'すおつもりがないのでしょう', 'すぎて', 'すぎで', 'すぎる', 'すぎるから', 'すげー', 'すことを', 'すごい', 'すごく', 'すって', 'すべての', 'すみません', 'する', 'するか', 'すること', 'することが', 'することに', 'することを', 'するぞ', 'するたび', 'すると', 'するに', 'するの', 'するのは', 'するのはお', 'するように', 'するわ', 'するんですか', 'すれば', 'すんですね', 'すんのよ', 'ずかしい', 'ずっと', 'せずにいこう', 'せてくれよ', 'せない', 'せになって', 'せめて', 'せるだろ', 'せるだろう', 'せるだろうが', 'せるの', 'せるのが', 'そういう', 'そういえば', 'そういや', 'そうか', 'そうすれば', 'そうだなあ', 'そうですか', 'そうですね', 'そうな', 'そして', 'そのう', 'そばに', 'そもそも', 'そりゃ', 'それから', 'それが', 'それでも', 'それと', 'それな', 'それなあ', 'それに', 'それは', 'それはいつか', 'それも', 'それを', 'そろそろ', 'そんな', 'ぞこないの', 'たいけど', 'たいです', 'たいと', 'たいのだ', 'たくて', 'たくない', 'たされる', 'ただいま', 'ただいまっ', 'ただいまー', 'たちが', 'たちの', 'たちは', 'たちを', 'たったる', 'たので', 'たぶん', 'たまえ', 'たまに', 'たんが', 'たんの', 'だから', 'だからな', 'だからね', 'だけが', 'だけで', 'だけど', 'だけにね', 'だけは', 'だしい', 'だそうです', 'だっけ', 'だった', 'だったか', 'だったのか', 'だったので', 'だったら', 'だったり', 'だったわ', 'だって', 'だとか', 'だなぁ', 'だなあ', 'だなー', 'だな～', 'だもう', 'だよ', 'だよな', 'だよね', 'だよー', 'だろう', 'だろうか', 'だろうが', 'だろうと', 'ちしております', 'ちしてます', 'ちだよね', 'ちなみに', 'ちます', 'ちゃだめだ', 'ちゃった', 'ちゃん', 'ちゃんが', 'ちゃんと', 'ちゃんに', 'ちゃんの', 'ちゃんは', 'ちゃんを', 'ちょっと', 'ちょっとした', 'ちょっとした', 'ちょっとは', 'っかた', 'っかむ', 'ったか', 'ったから', 'ったが', 'ったけど', 'ったし', 'ったの', 'ったので', 'ったのに', 'ったら', 'ったり', 'ったわ', 'ったんだけど', 'ったー', 'った～', 'っちゃいけない', 'っちゃったり', 'って', 'っていいもの', 'っていう', 'っていうか', 'っていうと', 'っていうと', 'っていうのは', 'っていうのもまた', 'っていた', 'っています', 'っている', 'っているなんて', 'っているので', 'っていろいろ', 'っておく', 'ってか', 'ってから', 'ってかれた', 'ってきた', 'ってきました', 'ってきます', 'ってください', 'ってくる', 'ってくるぜ', 'ってくるー', 'ってくれ', 'ってくれました', 'ってくれると', 'ってこい', 'ってことで', 'ってこよう', 'ってしまう', 'ってしまった', 'ってそういう', 'ってた', 'ってたから', 'ってたけど', 'ってたのに', 'ってたよ', 'ってたら', 'ってて', 'ってどんな', 'ってない', 'ってなに', 'ってなんだ', 'ってね', 'ってました', 'ってます', 'ってまた', 'ってみた', 'ってみたい', 'ってみたを', 'ってみたんよ', 'ってみて', 'ってみました', 'ってみるよ', 'っても', 'ってよ', 'ってる', 'ってるけど', 'ってるぜ', 'ってるの', 'ってるよ', 'ってるわ', 'ってろ', 'ってんだよ', 'っとう', 'っぽい', 'っぽさ', 'ついった', 'ついったー', 'ついて', 'ついでに', 'つくる', 'つけた', 'つけない', 'つぶやき', 'つまり', 'づいて', 'ていう', 'ていうか', 'ていけ', 'ていない', 'ていません', 'ている', 'てから', 'てきた', 'てきてもいいのよ', 'てください', 'てくるよ', 'てくれたの', 'てくれたのに', 'てくれよ', 'てくれよな', 'てことで', 'てたら', 'てても', 'てない', 'てなかった', 'てなんか', 'てぬか', 'てます', 'てみたい', 'てみてね', 'てよければ', 'てられないな', 'てれない', 'であったり', 'であって', 'であり', 'である', 'であれ', 'でいいよ', 'でいう', 'できた', 'できない', 'できました', 'できます', 'できる', 'でこんな', 'でした', 'でしたね', 'でしたー', 'でしょ', 'でしょうか', 'でしょうか', 'ですか', 'ですが', 'ですけどね', 'ですし', 'ですぞ', 'ですって', 'ですな', 'ですね', 'ですねー', 'ですのでご', 'ですみません', 'ですよ', 'ですよね', 'ですよー', 'でする', 'ですー', 'でないのに', 'でなく', 'ではありませんがね', 'ではない', 'ではなく', 'でもして', 'でもって', 'でもない', 'でやりたい', 'といい', 'という', 'というか', 'ということで', 'というと', 'というのは', 'というものは', 'というわけで', 'といえば', 'といったら', 'とかいう', 'とかだと', 'とかなる', 'とかなんでもお', 'とかの', 'とかはいい', 'とかも', 'ときて', 'ところで', 'としか', 'とした', 'として', 'としての', 'としては', 'としの', 'とします', 'とする', 'とするため', 'とすれ', 'とその', 'とても', 'とでも', 'とともに', 'となるのが', 'とのこと', 'とはいえ', 'とばっか', 'とりあえず', 'とりま', 'どういう', 'どうしたって', 'どうしたの', 'どうぞお', 'どうも', 'どうやって', 'どちらでも', 'どなたか', 'どもの', 'どれか', 'どんな', 'ないよ', 'なかった', 'ながら', 'なこと', 'なことで', 'なさい', 'なさいまし', 'なさいました', 'なさいませ', 'なさらずに', 'なぜか', 'なときに', 'などを', 'なにそれ', 'なの', 'なのか', 'なのかな', 'なのが', 'なのだ', 'なので', 'なのです', 'なのに', 'なように', 'ならば', 'なるほど', 'なんか', 'なんだ', 'なんだい', 'なんだか', 'なんだけど', 'なんだよ', 'なんだー', 'なんて', 'なんで', 'なんです', 'なんですかこれは', 'なんですよ', 'なんと', 'なんと', 'なんという', 'なんのために', 'にある', 'にいてその', 'にいませんが', 'にいようね', 'にいる', 'にいるとか', 'にいれて', 'にいれば', 'において', 'における', 'にかわって', 'にしか', 'にした', 'にしたら', 'にして', 'にしても', 'にしない', 'にしよう', 'にしろ', 'にしろよ', 'にする', 'にするか', 'にするからな', 'にすると', 'にするな', 'にするなら', 'にせず', 'にたい', 'にたくなる', 'について', 'についての', 'については', 'につく', 'にでも', 'にとって', 'にどうぞ', 'にどうぞー', 'にどんな', 'になぁ', 'にない', 'になった', 'になったものだ', 'になったら', 'になって', 'になっていたら', 'になっている', 'になってください', 'になってよ', 'になってる', 'にならない', 'にならん', 'になり', 'になりきって', 'になりたい', 'になりました', 'になります', 'になりますように', 'になる', 'になるから', 'になると', 'になるまで', 'になるような', 'になるように', 'になれ', 'になれあと', 'になれたなら', 'になれない', 'になれなかった', 'になれよ', 'になろうよ', 'にぬき', 'にはあって', 'にはどんな', 'にはない', 'にやると', 'によく', 'によって', 'によっては', 'による', 'によると', 'ぬかな', 'のあなた', 'のあなた', 'のあなた', 'のあなたへ', 'のある', 'のいい', 'のいて', 'のおすすめ', 'のこと', 'のことが', 'のことを', 'のせい', 'のせいで', 'のせいですよ', 'のその', 'のため', 'のために', 'のための', 'のついた', 'のつく', 'のつぶやき', 'のつもり', 'のとこ', 'のとこから', 'のところ', 'のどれかを', 'のない', 'のほうが', 'のほうもよろしく～', 'のまとめ', 'のみの', 'のやつ', 'のような', 'のように', 'はありません', 'はいつも', 'はかなり', 'はここまで', 'はこちら', 'はこの', 'はこれ', 'はさせない', 'はした', 'はしたよ', 'はしない', 'はじめたの', 'はずっとお', 'はその', 'はそろそろ', 'はだいたい', 'はっきり', 'はできる', 'はどうかな', 'はどうして', 'はなぜ', 'はなよ', 'はまったく', 'はみんな', 'はもう', 'はやっぱり', 'は～い', 'ばしました', 'ばない', 'ばないということから', 'ひとまず', 'びくださーい', 'びたい', 'びました', 'びます', 'ぶりに', 'べえを', 'べたい', 'べたいのですね', 'べたよ', 'べちゃうぞ', 'べてみるのも', 'べてる', 'べました', 'べます', 'べやがって', 'べらが', 'べられちゃう', 'べるよ', 'べればいいじゃない', 'ほかてらー', 'ほしい', 'ほどの', 'ほんと', 'ほんとに', 'ぼくの', 'ぼくは', 'まさかの', 'まさに', 'ましい', 'ましすぎて', 'ました', 'ましょ', 'ますかね', 'ますわ', 'またお', 'またね', 'またよろしくお', 'まだあと', 'まぢで', 'まった', 'まったく', 'まったく', 'まってます', 'まであと', 'までは', 'まどか', 'まなくちゃ', 'まらない', 'まりきらない', 'まりそう', 'まるで', 'まれた', 'まれたって', 'まれたのは', 'まれたり', 'まれて', 'まれています', 'まれの', 'まれます', 'まれる', 'みします', 'みたい', 'みたいです', 'みたいな', 'みたいなものなので', 'みたいなものなので', 'みたいに', 'みなさい', 'みなさいませ', 'みなさいませー', 'みなさん', 'みなんだけどさ', 'みました', 'みます', 'みんな', 'みんなと', 'みんなの', 'むから', 'むしろ', 'むの���', 'むんなら', 'めがいいかな', 'めたい', 'めたお', 'めたじゃん', 'めたなう', 'めたみたいなの', 'めたり', 'めだったかな', 'めてください', 'めてくれる', 'めてね', 'めての', 'めてよ', 'めてよう', 'めです', 'めない', 'めないで', 'めなさい', 'めました', 'めまして', 'めます', 'めません', 'めようか', 'めるか', 'めるべき', 'もいい', 'もいきます', 'もいない', 'もきくよ', 'もしかして', 'もしくは', 'もしや', 'もっと', 'もない', 'もないし', 'もなく', 'もねぇ', 'ものすごく', 'もはや', 'もみんな', 'もよかったら', 'やから', 'やった', 'やったなら', 'やったら', 'やってから', 'やってます', 'やっと', 'やっといたら', 'やっぱ', 'やっぱり', 'やなぁ', 'やないよ', 'やはり', 'やばい', 'やると', 'やれば', 'ようぜー', 'ようと', 'ような', 'ように', 'ようやく', 'よかったら', 'よければ', 'よって', 'よりです', 'よりも', 'よろしく', 'よろしくお', 'よろしければ', 'らしい', 'らしさを', 'らせいただければ', 'らせします', 'らせろ', 'らない', 'らないと', 'らないよ', 'らなかった', 'られざる', 'られた', 'られたい', 'られない', 'られる', 'られるし', 'らんけど', 'りいたします', 'りしたい', 'りします', 'りそうですが', 'りたい', 'りつづけて', 'りです', 'りでの', 'りない', 'りないからです', 'りないのか', 'りないませ', 'りなさ', 'りなさい', 'りなさいです', 'りなさいませ', 'りなさいませー', 'りなの', 'りにしか', 'りにしました', 'りのに', 'りのは', 'りました', 'りましたー', 'りましょう', 'りましょうね', 'ります', 'りますか', 'りますが', 'るかな', 'るたん', 'るであろう', 'るという', 'るなう', 'るなって', 'るなら', 'るには', 'るのか', 'るのだ', 'るのは', 'るべき', 'るべし', 'るような', 'るんだ', 'れさせ', 'れさまでした', 'れさまです', 'れさまー', 'れする', 'れたい', 'れたかい', 'れたなう', 'れたので', 'れたよ', 'れたら', 'れだか', 'れっした', 'れている', 'れてた', 'れてないかい', 'れてみた', 'れてる', 'れです', 'れない', 'れないうちに', 'れないし', 'れないのよ', 'れなかった', 'ればいいんだね', 'れました', 'れますね', 'れますように', 'れられない', 'れるだろ', 'れると', 'れるといいな', 'ろうか', 'ろうかな', 'ろうかなと', 'ろしい', 'わかりました', 'わせた', 'わせて', 'わせる', 'わせろ', 'わたし', 'わたしが', 'わたしで', 'わたしと', 'わたしに', 'わたしの', 'わたしは', 'わたしも', 'わたしを', 'わった', 'わったぁ', 'わったら', 'わっちゃう', 'わって', 'わってます', 'わない', 'わないで', 'わないであろう', 'わないと', 'わないよ', 'わねぇか', 'わらず', 'わらない', 'わりか', 'わりと', 'わりますが', 'われた', 'われたい', 'われない', 'われば', 'われました', 'われます', 'われますが', 'われる', 'われると', 'わんのだろう', 'をいつも', 'をかいてください', 'をかいてください', 'をください', 'をした', 'をしたよ', 'をしたら', 'をして', 'をしていて', 'をしています', 'をしない', 'をしますか', 'をしよう', 'をする', 'をすると', 'をするのか', 'をすればのか', 'をずっと', 'をついた', 'をつかって', 'をつかって', 'をつけください', 'をつけて', 'をつけなさい', 'をつける', 'をやった', 'をやってくれる', 'をやめる', 'をやりました', 'をやる', 'んさん', 'んさんが', 'んさんの', 'んさんは', 'んだか', 'んだら', 'んであげてください', 'んでいて', 'んでいない', 'んでいる', 'んできた', 'んでください', 'んでくれると', 'んでない', 'んでました', 'んでやる', 'んでゆけ', 'んでる', 'アイコン', 'アイテム', 'アカウント', 'アタシ', 'アップ', 'アドレス', 'アーティスト', 'イケメン', 'イベント', 'イメージ', 'インストール', 'インターネット', 'オフィシャル', 'オリジナル', 'カップ', 'カンニング', 'ガール', 'キャラ', 'キュゥ', 'キュウ', 'キーボード', 'クラス', 'クラスタ', 'クリア', 'グループ', 'ケータイ', 'ケーブル', 'コード', 'サイト', 'サンタ', 'サービス', 'シリーズ', 'シンプル', 'シーン', 'ジャンル', 'スーパー', 'セット', 'ソフト', 'タイトル', 'チェック', 'チョコ', 'ツイッター', 'ツイート', 'ティロ', 'テレビ', 'テーマ', 'データ', 'トイレ', 'ネット', 'バイト', 'パソコン', 'ファイル', 'ファン', 'フィナーレ', 'フォルダ', 'フォロワー', 'フォロー', 'ブラシ', 'ブログ', 'ブロック', 'プレイ', 'ページ', 'ホント', 'ボタン', 'ポーズ', 'マイリスト', 'マギカ', 'メディア', 'メール', 'モニタ', 'モード', 'モード', 'ユニット', 'リアル', 'リスト', 'リツイート', 'リフォロークラスタ', 'リプライ', 'リムーブ', 'レベル', 'レポート', 'ワタシ', '個人的', '大丈夫', '有意義', '誕生日', 'げてみる', 'かしいものを', 'しくなる', 'もかも', 'にすると', 'にしてください', 'うことを', 'そうだな', 'げてみる', 'かしいものを', 'いていますよ', 'をつこう', 'かさず', 'しております', 'がっていると', 'かれています', 'これからも', 'をとりました', 'してくれた', 'えるかなぁ', 'いじゃないわ', 'したりします', 'いつの', 'わかる', 'しみに', 'たらいいな', 'たらいいなと', 'けてよ', 'しくなる', 'れましたが', 'えします', 'どうせ', 'わります', 'をつけると', 'してくれたみなさん', 'えてくれる', 'えてくれるよ', 'けだった', 'きたくない', 'こっちも', 'てくれると', 'てるのは', 'してくれる', 'かさずに']
      @deny_set = deny_list.map { |w| [w, true] }.to_h
      @limit = 100
    end

    def count_words(text)
      map = Hash.new(0)

      @allow_list.each do |word|
        if (count = text.split(word).length - 1) && count > 0
          map[word] = count
        end
      end

      regexp = /[一-龠〆ヵヶ々]+|[ぁ-んー～]+|[ァ-ヴー～]+|[ａ-ｚＡ-Ｚ０-９]+|[、。！!？?]+/
      text.scan(regexp).each do |word|
        word = word.split(/[？！?!。、ｗ]/).join('')
        word = word.split(/ー{2,}/).join('')

        next if @deny_set[word] || word.length <= 2
        map[word] += 1
      end

      map.delete_if { |_, count| count <= 1 }.sort_by { |_, count| -count }.take(@limit).to_h
    end
  end

  module Misc2
    module_function

    PROFILE_SPECIAL_WORDS = %w(20↑ 成人済 腐女子)
    PROFILE_SPECIAL_REGEXP = nil
    PROFILE_EXCLUDE_WORDS = %w(in at of my to no er by is RT DM the and for you inc Inc com from info next gmail 好き こと 最近 紹介 連載 発売 依頼 情報 さん ちゃん くん 発言 関係 もの 活動 見解 所属 組織 代表 連絡 大好き サイト ブログ つぶやき 株式会社 最新 こちら 届け お仕事 ツイ 返信 プロ 今年 リプ ヘッダー アイコン アカ アカウント ツイート たま ブロック 無言 時間 お願い お願いします お願いいたします イベント フォロー フォロワー フォロバ スタッフ 自動 手動 迷言 名言 非公式 リリース 問い合わせ ツイッター)
    PROFILE_EXCLUDE_REGEXP = Regexp.union(/\w+@\w+\.(com|co\.jp)/, %r[\d{2,4}(年|/)\d{1,2}(月|/)\d{1,2}日], %r[\d{1,2}/\d{1,2}], /\d{2}th/, URI.regexp)

    def count_freq_hashtags(tweets, with_prefix: true, use_regexp: false, debug: false)
      puts "tweets: #{tweets.size}" if debug
      return {} if tweets.blank?

      prefix = %w(# ＃)
      regexp = /[#＃]([Ａ-Ｚａ-ｚA-Za-z_一-鿆0-9０-９ぁ-ヶｦ-ﾟー]+)/

      tweets =
          if use_regexp
            tweets.select { |t| t.text && prefix.any? { |char| t.text.include?(char)} }
          else
            tweets.select { |t| include_hashtags?(t) }
          end
      puts "tweets with hashtag: #{tweets.size}" if debug

      hashtags =
          if use_regexp
            tweets.map { |t| t.text.scan(regexp).flatten.map(&:strip) }
          else
            tweets.map { |t| extract_hashtags(t) }
          end.flatten
      hashtags = hashtags.map { |h| "#{prefix[0]}#{h}" } if with_prefix

      hashtags.each_with_object(Hash.new(0)) { |h, memo| memo[h] += 1 }.sort_by { |k, v| [-v, -k.size] }.to_h
    end

    def hashtag_clusters(hashtags, limit: 10, debug: false)
      puts "hashtags: #{hashtags.take(10)}" if debug

      hashtag, count = hashtags.take(3).each_with_object(Hash.new(0)) do |tag, memo|
        tweets = search(tag)
        puts "tweets #{tag}: #{tweets.size}" if debug
        memo[tag] = count_freq_hashtags(tweets).reject { |t, c| t == tag }.values.sum
      end.max_by { |_, c| c }

      hashtags = count_freq_hashtags(search(hashtag)).reject { |t, c| t == hashtag }.keys
      queries = hashtags.take(3).combination(2).map { |ary| ary.join(' AND ') }
      puts "selected #{hashtag}: #{queries.inspect}" if debug

      tweets = queries.map { |q| search(q) }.flatten
      puts "tweets #{queries.inspect}: #{tweets.size}" if debug

      if tweets.empty?
        tweets = search(hashtag)
        puts "tweets #{hashtag}: #{tweets.size}" if debug
      end

      members = tweets.map { |t| t.user }
      puts "members count: #{members.size}" if debug

      count_freq_words(members.map { |m| m.description  }, special_words: PROFILE_SPECIAL_WORDS, exclude_words: PROFILE_EXCLUDE_WORDS, special_regexp: PROFILE_SPECIAL_REGEXP, exclude_regexp: PROFILE_EXCLUDE_REGEXP, debug: debug).take(limit)
    end

    private

    def include_hashtags?(tweet)
      tweet.entities&.hashtags&.any?
    end

    def extract_hashtags(tweet)
      tweet.entities.hashtags.map { |h| h.text }
    end
  end
end
