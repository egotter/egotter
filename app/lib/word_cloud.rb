class WordCloud
  def count_words(text, parser: :natto, min_word_length: 2, min_count: 2)
    text = text.gsub(%r{(https?://)?[\w/.\-]+}, '').gsub(/\n/, ' ')

    parsed = (parser == :natto) ? natto_parse(text) : parse(text)
    words = parsed.select { |_, desc| desc && !desc.match?(/^(助詞|助動詞|記号)/) }.map(&:first)
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

  class << self
    def mecab_model
      if instance_variable_defined?(:@mecab_model)
        @mecab_model
      else
        require 'mecab'
        @mecab_model = MeCab::Model.create("-d #{`mecab-config --dicdir`.chomp}/mecab-ipadic-neologd/")
      end
    end
  end

  private

  def mecab_tagger
    self.class.mecab_model.createTagger
  end

  def natto_parse(text)
    require 'natto' unless defined?(Natto)
    dicdir = "#{`mecab-config --dicdir`.chomp}/mecab-ipadic-neologd/"
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
end
