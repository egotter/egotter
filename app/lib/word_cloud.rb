require 'natto'

class WordCloud
  # TODO This regexp matches to general English word
  URL_REGEXP = %r{(https?://)?[\w/.\-]+}

  def count_words(text, parser: :natto, min_word_length: 2, min_count: 2)
    text = text.remove(URL_REGEXP).remove(/\0/).gsub(/\n/, ' ')

    parsed = (parser == :natto) ? natto_parse(text) : parse(text)
    words = parsed.map { |p| extract_noun(p) }.compact
    words_count = words.each_with_object(Hash.new(0)) { |word, memo| memo[word] += 1 }

    words_count.each do |word, count|
      if word.include?(' ') ||
          word.match?(/^(\p{hiragana}){2}$/) ||
          word.length < min_word_length ||
          count < min_count
        words_count.delete(word)
      end
    end

    words_count.sort_by { |_, v| -v }.to_h
  end

  private

  def natto_parse(text)
    dicdir = `#{ENV['MECAB_CONFIG'] || 'mecab-config'} --dicdir`.chomp + '/mecab-ipadic-neologd/'
    Natto::MeCab.new(dicdir: dicdir).parse(truncate_text(text)).split("\n").map { |l| l.split("\t") }
  end

  def parse(text)
    mecab_tagger.parse(truncate_text(text)).split("\n").map { |l| l.split("\t") }
  end

  MAX_BYTESIZE = 40.kilobytes

  def truncate_text(text)
    while text.bytesize > MAX_BYTESIZE do
      text = text.truncate(text.size * 0.9, omission: '')
    end
    text
  end

  def extract_noun(parsed)
    parsed[0] if (parsed[1] && !parsed[1].match?(/^(助詞|助動詞|記号)/))
  end
end
