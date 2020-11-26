class ClusterFinder

  MIN_WORD_LENGTH = 2
  MIN_LIST_MEMBERS = 10
  MAX_LIST_MEMBERS = 300
  MAX_MEMBERS = 3000
  MAX_LISTS = 50
  CONTENT_RATE = 0.3
  LIMIT = 10

  def initialize(client)
    @client = client
  end

  def list_clusters(user, lists: nil, min_word_length: MIN_WORD_LENGTH, min_list_members: MIN_LIST_MEMBERS, max_list_members: MAX_LIST_MEMBERS, max_members: MAX_MEMBERS, max_lists: MAX_LISTS, content_rate: CONTENT_RATE, limit: LIMIT)
    lists = fetch_lists(user) unless lists
    lists = lists.sort_by(&:member_count)
    logger.debug { "#{__method__}: lists=#{inspect_lists(lists)}" }
    return {} if lists.empty?

    words_count = count_words(lists, min_word_length: min_word_length)
    logger.debug { "#{__method__}: words_count=#{words_count}" }
    return {} if words_count.empty?

    lists = filter_lists_by_words(lists, words_count.keys)
    logger.debug { "#{__method__}: word_filtered_lists=#{inspect_lists(lists)}" }
    return {} if lists.empty?

    lists = filter_lists_by_member_count(lists, min: min_list_members, max: max_list_members)
    logger.debug { "#{__method__}: member_count_filtered_lists=#{inspect_lists(lists)}" }
    return {} if lists.empty?

    lists = filter_lists_by_total_members(lists, max: max_members)
    logger.debug { "#{__method__}: total_members_filtered_lists=#{inspect_lists(lists)}" }
    return {} if lists.empty?

    lists = filter_lists_by_total_lists(lists, max_total_lists: max_lists)
    logger.debug "#{__method__}: total_lists_filtered_lists=#{inspect_lists(lists)}"
    return {} if lists.empty?

    members_count = count_members(lists)
    logger.debug { "#{__method__}: members=#{members_count.size} members_count=#{members_count.map { |k, v| [k.screen_name, v] }}" }
    return {} if members_count.empty?

    members_count = filter_members_by_content_rate(members_count, lists.size, rate: content_rate)
    logger.debug { "#{__method__}: content_rate_filtered_members=#{members_count.map { |m, c| [m.screen_name, c] }}" }
    return {} if members_count.empty?

    count_keywords(members_count.map(&:first).map(&:description)).take(limit)
  end

  private

  def fetch_lists(user, count: 500)
    @client.twitter.memberships(user, count: count).attrs[:lists].map { |l| Hashie::Mash.new(l) }
  end

  def fetch_list_members(list)
    @client.twitter.list_members(list.id).attrs[:users].map { |u| Hashie::Mash.new(u) }
  rescue Twitter::Error::NotFound => e
    logger.debug "#{__method__}: #{e.inspect} list_id=#{list.id} full_name=#{list.full_name}"
    nil
  end

  LIST_EXCLUDE_REGEXP = %r(list[0-9]*|people-ive-faved|twizard-magic-list|my-favstar-fm-list|timeline-list|conversationlist|who-i-met)
  LIST_EXCLUDE_WORDS = %w(it list people who met)

  # リスト名を - で分割、1文字の単語を除去、出現頻度の降順かつ文字数の降順でソート
  def count_words(lists, min_word_length: 2)
    lists.map { |l| list_name(l) }.
        reject { |n| n.match?(LIST_EXCLUDE_REGEXP) }.
        map { |n| n.split('-') }.flatten.
        reject { |w| LIST_EXCLUDE_WORDS.include?(w) }.
        reject { |w| w.size < min_word_length }.
        map { |w| SYNONYM_WORDS.has_key?(w) ? SYNONYM_WORDS[w] : w }.
        each_with_object(Hash.new(0)) { |w, memo| memo[w] += 1 }.
        sort_by { |word, count| [-count, -word.size] }.to_h
  end

  # 出現頻度の高い単語を名前に含むリストを抽出
  def filter_lists_by_words(lists, words, min: 2)
    filtered = words.map { |word| lists.select { |l| list_name(l).include?(word) } }
    filtered.size.times do |n|
      candidates = filtered.take(n + 1).flatten.uniq(&:id)
      if candidates.size >= min
        return candidates
      end
    end
    []
  end

  def filter_lists_by_member_count(lists, min: MIN_LIST_MEMBERS, max: MAX_LIST_MEMBERS)
    return if lists.empty?
    10.times do
      result = lists.select { |list| (min..max).include?(list.member_count) }
      return result if result.any?

      min *= 0.9
      max *= 0.9
    end
    lists
  end

  def filter_lists_by_total_members(lists, max: MAX_MEMBERS)
    lists.size.times do |n|
      candidates = lists[0..(-1 - n)]
      if candidates.map(&:member_count).sum < max
        return candidates
      end
    end
    []
  end

  def filter_lists_by_total_lists(lists, max_total_lists: 50)
    lists[0..(max_total_lists - 1)]
  end

  def count_members(lists)
    members = lists.map { |list| fetch_list_members(list) }.compact.flatten
    members.each_with_object(Hash.new(0)) { |member, memo| memo[member.id] += 1 }.sort_by { |_, v| -v }.
        map { |id, count| [members.find { |m| m.id == id }, count] }.to_h
  end

  def filter_members_by_content_rate(members_count, lists_size, min_members: 10, rate: 0.3)
    result = nil
    10.times do
      result = members_count.select { |_, count| count > lists_size * rate }
      break if result.size > min_members
      rate -= 0.05
    end
    result
  end

  PROFILE_EXCLUDE_WORDS = %w(in at of my to no er by is RT DM the and for you inc Inc com from info next gmail 好き こと 最近 紹介 連載 発売 依頼 情報 さん ちゃん くん 発言 関係 もの 活動 見解 所属 組織 代表 連絡 大好き サイト ブログ つぶやき 株式会社 最新 こちら 届け お仕事 ツイ 返信 プロ 今年 リプ ヘッダー アイコン アカ アカウント ツイート たま ブロック 無言 時間 お願い お願いします お願いいたします イベント フォロー フォロワー フォロバ スタッフ 自動 手動 迷言 名言 非公式 リリース 問い合わせ ツイッター)
  PROFILE_EXCLUDE_REGEXP = Regexp.union(/\w+@\w+\.(com|co\.jp)/, %r[\d{2,4}(年|/)\d{1,2}(月|/)\d{1,2}日], %r[\d{1,2}/\d{1,2}], /\d{2}th/, URI.regexp)

  SHORT_HIRAGANA_REGEXP = /^(\p{hiragana}){2}$/
  SHORT_DIGITS_REGEXP = /^\d{2}$/

  def count_keywords(texts, min_length: 2, max_length: 5, exclude_words: PROFILE_EXCLUDE_WORDS, exclude_regexp: PROFILE_EXCLUDE_REGEXP)
    text = texts.join(' ').remove(exclude_regexp)
    words = natto_parse(text).select { |_, desc| desc && desc.match?(/^名詞/) }.map(&:first)

    words.reject { |w| w.size < min_length || max_length < w.size || exclude_words.include?(w) || w.match?(SHORT_DIGITS_REGEXP) || w.match?(SHORT_HIRAGANA_REGEXP) }.
        each_with_object(Hash.new(0)) { |word, memo| memo[word] += 1 }.
        sort_by { |k, v| [-v, -k.size] }.to_h
  end

  def natto_parse(text)
    require 'natto'
    dicdir = "#{`mecab-config --dicdir`.chomp}/mecab-ipadic-neologd/"
    Natto::MeCab.new(dicdir: dicdir).parse(truncate_text(text)).split("\n").map { |l| l.split("\t") }
  end

  MAX_BYTESIZE = 40.kilobytes

  def truncate_text(text)
    while text.bytesize > MAX_BYTESIZE do
      text = text.truncate(text.size * 0.9, omission: '')
    end
    text
  end

  SYNONYM_WORDS = (
  %w(cosplay cosplayer cosplayers coser cos こすぷれ コスプレ レイヤ レイヤー コスプレイヤー レイヤーさん).map { |w| [w, 'coplay'] } +
      %w(tsukuba tkb).map { |w| [w, 'tsukuba'] } +
      %w(waseda 早稲田 早稲田大学).map { |w| [w, 'waseda'] } +
      %w(keio 慶應 慶應義塾).map { |w| [w, 'keio'] } +
      %w(gakusai gakuensai 学祭 学園祭).map { |w| [w, 'gakusai'] } +
      %w(kosen kousen).map { |w| [w, 'kosen'] } +
      %w(anime アニメ).map { |w| [w, 'anime'] } +
      %w(photo photos).map { |w| [w, 'photo'] } +
      %w(creator creater クリエイター).map { |w| [w, 'creator'] } +
      %w(illustrator illustrater 絵師).map { |w| [w, 'illustrator'] } +
      %w(artist art artists アート 芸術).map { |w| [w, 'artist'] } +
      %w(design デザイン).map { |w| [w, 'design'] } +
      %w(kawaii かわいい).map { |w| [w, 'kawaii'] } +
      %w(idol あいどる アイドル 美人).map { |w| [w, 'idol'] } +
      %w(music musician musicians dj netlabel label レーベル おんがく 音楽家 音楽).map { |w| [w, 'music'] } +
      %w(engineer engineers engineering えんじにあ tech 技術 技術系 hacker coder programming programer programmer geek rubyist ruby scala java lisp).map { |w| [w, 'engineer'] } +
      %w(internet インターネット).map { |w| [w, 'internet'] }
  ).to_h

  def list_name(list)
    list.full_name.split('/')[1]
  end

  def inspect_lists(lists)
    lists.map { |list| [list.id, list_name(list), list.member_count] }
  end

  def logger
    Rails.logger
  end
end
