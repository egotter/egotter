class UrlShortener
  def self.shorten(url)
    key = ENV['URL_SHORTENER_KEY']
    res = HTTParty.post("https://www.googleapis.com/urlshortener/v1/url?key=#{key}",
                        body: {longUrl: url}.to_json,
                        headers: {'Content-Type' => 'application/json'})
    JSON.parse(res.body)['id']
  rescue => e
    logger.warn "UrlShortener #{e.class} #{e.message} #{url}"
    url
  end
end
