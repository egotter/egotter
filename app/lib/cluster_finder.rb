class ClusterFinder
  def list_clusters(user: nil, lists: nil, shrink: false, shrink_limit: 100, list_member: 300, total_member: 3000, total_list: 50, rate: 0.3, limit: 10, debug: false)
    unless lists
      lists = fetch_lists(user)
    end
    lists = lists.sort_by { |li| li.member_count }
    puts "lists: #{lists.size} (#{lists.map { |li| li.member_count }.join(', ')})" if debug
    return {} if lists.empty?

    open('lists.txt', 'w') {|f| f.write lists.map(&:full_name).join("\n") } if debug

    list_special_words = %w()
    list_exclude_regexp = %r(list[0-9]*|people-ive-faved|twizard-magic-list|my-favstar-fm-list|timeline-list|conversationlist|who-i-met)
    list_exclude_words = %w(it list people who met)

    # リスト名を - で分割 -> 1文字の単語を除去 -> 出現頻度の降順でソート
    words = lists.map { |li| li.full_name.split('/')[1] }.
        select { |n| !n.match(list_exclude_regexp) }.
        map { |n| n.split('-') }.flatten.
        delete_if { |w| w.size < 2 || list_exclude_words.include?(w) }.
        map { |w| SYNONYM_WORDS.has_key?(w) ? SYNONYM_WORDS[w] : w }.
        each_with_object(Hash.new(0)) { |w, memo| memo[w] += 1 }.
        sort_by { |k, v| [-v, -k.size] }

    puts "words: #{words.take(10)}" if debug
    return {} if words.empty?

    # 出現頻度の高い単語を名前に含むリストを抽出
    _words = []
    lists =
        filter(lists, min: 2) do |li, i|
          _words = words[0..i].map(&:first)
          name = li.full_name.split('/')[1]
          _words.any? { |w| name.include?(w) }
        end
    puts "lists include #{_words.inspect}: #{lists.size} (#{lists.map { |li| li.member_count }.join(', ')})" if debug
    return {} if lists.empty?

    # 中間の 25-75% のリストを抽出
    while lists.size > shrink_limit
      percentile25 = ((lists.length * 0.25).ceil) - 1
      percentile75 = ((lists.length * 0.75).ceil) - 1
      lists = lists[percentile25..percentile75]
      puts "lists sliced by 25-75 percentile: #{lists.size} (#{lists.map { |li| li.member_count }.join(', ')})" if debug
    end if shrink || lists.size > shrink_limit

    # メンバー数がしきい値より少ないリストを抽出
    _list_member = 0
    _min_list_member = 10 < lists.size ? 10 : 0
    _lists =
        filter(lists, min: 2) do |li, i|
          _list_member = list_member * (1.0 + 0.25 * i)
          _min_list_member < li.member_count && li.member_count < _list_member
        end
    lists = _lists.empty? ? [lists[0]] : _lists
    puts "lists limited by list member #{_min_list_member}..#{_list_member.round}: #{lists.size} (#{lists.map { |li| li.member_count }.join(', ')})" if debug
    return {} if lists.empty?

    # トータルメンバー数がしきい値より少なくなるリストを抽出
    _lists = []
    lists.size.times do |i|
      _lists = lists[0..(-1 - i)]
      if _lists.map { |li| li.member_count }.sum < total_member
        break
      else
        _lists = []
      end
    end
    lists = _lists.empty? ? [lists[0]] : _lists
    puts "lists limited by total members #{total_member}: #{lists.size} (#{lists.map { |li| li.member_count }.join(', ')})" if debug
    return {} if lists.empty?

    # リスト数がしきい値より少なくなるリストを抽出
    if lists.size > total_list
      lists = lists[0..(total_list - 1)]
    end
    puts "lists limited by total lists #{total_list}: #{lists.size} (#{lists.map { |li| li.member_count }.join(', ')})" if debug
    return {} if lists.empty?

    members = lists.map do |li|
      begin
        fetch_list_members(li.id)
      rescue Twitter::Error::NotFound => e
        puts "#{__method__}: #{e.class} #{e.message} #{li.id} #{li.full_name} #{li.mode}" if debug
        nil
      end
    end.compact.flatten
    puts "candidate members: #{members.size}" if debug
    return {} if members.empty?

    open('members.txt', 'w') {|f| f.write members.map{ |m| m.description.gsub(/\R/, ' ') }.join("\n") } if debug

    3.times do
      _members = members.each_with_object(Hash.new(0)) { |member, memo| memo[member] += 1 }.
          select { |_, v| lists.size * rate < v }.keys
      if _members.size > 100
        members = _members
        break
      else
        rate -= 0.05
      end
    end
    puts "members included multi lists #{rate.round(3)}: #{members.size}" if debug

    count_freq_words(members.map { |m| m.description }, special_words: PROFILE_SPECIAL_WORDS, exclude_words: PROFILE_EXCLUDE_WORDS, special_regexp: PROFILE_SPECIAL_REGEXP, exclude_regexp: PROFILE_EXCLUDE_REGEXP, debug: debug).take(limit)
  end

  def fetch_lists(user, count: 500)
    Bot.api_client.twitter.memberships(user, count: count).attrs[:lists].map { |l| Hashie::Mash.new(l) }
  end

  def fetch_list_members(list_id)
    Bot.api_client.twitter.list_members(list_id).attrs[:users].map { |u| Hashie::Mash.new(u) }
  end

  def count_freq_words(texts, special_words: [], exclude_words: [], special_regexp: nil, exclude_regexp: nil, debug: false)
    candidates, remains = texts.partition { |desc| desc.scan('/').size > 2 }
    slash_freq = count_by_word(candidates, delim: '/', exclude_regexp: exclude_regexp)
    puts "words splitted by /: #{slash_freq.take(10)}" if debug

    candidates, remains = remains.partition { |desc| desc.scan('|').size > 2 }
    pipe_freq = count_by_word(candidates, delim: '|', exclude_regexp: exclude_regexp)
    puts "words splitted by |: #{pipe_freq.take(10)}" if debug

    noun_freq = count_by_word(remains, tagger: build_tagger, special_words: special_words, exclude_words: exclude_words, special_regexp: special_regexp, exclude_regexp: exclude_regexp)
    puts "words tagged as noun: #{noun_freq.take(10)}" if debug

    slash_freq.merge(pipe_freq) { |_, old, neww| old + neww }.
        merge(noun_freq) { |_, old, neww| old + neww }.sort_by { |k, v| [-v, -k.size] }
  end

  def count_by_word(texts, delim: nil, tagger: nil, min_length: 2, max_length: 5, special_words: [], exclude_words: [], special_regexp: nil, exclude_regexp: nil)
    texts = texts.dup

    frequency = Hash.new(0)
    if special_words.any?
      texts.each do |text|
        special_words.map { |sw| [sw, text.scan(sw)] }
            .delete_if { |_, matched| matched.empty? }
            .each_with_object(frequency) { |(word, matched), memo| memo[word] += matched.size }

      end
    end

    if exclude_regexp
      texts = texts.map { |t| t.remove(exclude_regexp) }
    end

    if delim
      texts = texts.map { |t| t.split(delim) }.flatten.map(&:strip)
    end

    if tagger
      texts = texts.map { |t| tagger.parse(t).split("\n") }.flatten.
          select { |line| line.include?('名詞') }.
          map { |line| line.split("\t")[0] }
    end

    texts.delete_if { |w| w.empty? || w.size < min_length || max_length < w.size || exclude_words.include?(w) || w.match(/\d{2}/) }.
        each_with_object(frequency) { |word, memo| memo[word] += 1 }.
        sort_by { |k, v| [-v, -k.size] }.to_h
  end

  PROFILE_SPECIAL_WORDS = %w(20↑ 成人済 腐女子)
  PROFILE_SPECIAL_REGEXP = nil
  PROFILE_EXCLUDE_WORDS = %w(in at of my to no er by is RT DM the and for you inc Inc com from info next gmail 好き こと 最近 紹介 連載 発売 依頼 情報 さん ちゃん くん 発言 関係 もの 活動 見解 所属 組織 代表 連絡 大好き サイト ブログ つぶやき 株式会社 最新 こちら 届け お仕事 ツイ 返信 プロ 今年 リプ ヘッダー アイコン アカ アカウント ツイート たま ブロック 無言 時間 お願い お願いします お願いいたします イベント フォロー フォロワー フォロバ スタッフ 自動 手動 迷言 名言 非公式 リリース 問い合わせ ツイッター)
  PROFILE_EXCLUDE_REGEXP = Regexp.union(/\w+@\w+\.(com|co\.jp)/, %r[\d{2,4}(年|/)\d{1,2}(月|/)\d{1,2}日], %r[\d{1,2}/\d{1,2}], /\d{2}th/, URI.regexp)

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

  def normalize_synonym(words)
    words.map { |w| SYNONYM_WORDS.has_key?(w) ? SYNONYM_WORDS[w] : w }
  end

  def filter(lists, min:)
    min = [min, lists.size].min
    _lists = []
    3.times do |i|
      _lists = lists.select { |li| yield(li, i) }
      break if _lists.size >= min
    end
    _lists
  end

  def build_tagger
    require 'mecab'
    MeCab::Tagger.new("-d #{`mecab-config --dicdir`.chomp}/mecab-ipadic-neologd/")
  rescue => e
    puts "Add gem 'mecab' to your Gemfile."
    raise e
  end
end
