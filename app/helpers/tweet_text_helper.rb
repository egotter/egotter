module TweetTextHelper
  def honorific_name(name)
    "#{name} #{t('dictionary.honorific')}"
  end
end
