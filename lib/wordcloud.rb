class Wordcloud
  def self.generate
    %x(python "#{::Rails.root}/bin/kumo/kumo.py" tweets.txt out.png)
  end
end

if $0 == __FILE__
  Wordcloud.generate
end
