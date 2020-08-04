module TweetTextHelper
  def honorific_name(name)
    "#{name} #{t('dictionary.honorific')}"
  end

  def honorific_names(names, delim: t('dictionary.delim'))
    names.map { |name| honorific_name(name) }.join(delim)
  end
end
