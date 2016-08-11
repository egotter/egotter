module Util
  class UrlShortener
    def self.shorten(url)
      return '' if url.blank?

      key = ENV['URL_SHORTENER_KEY']
      res = HTTParty.post("https://www.googleapis.com/urlshortener/v1/url?key=#{key}",
                          body: {longUrl: url}.to_json,
                          headers: {'Content-Type' => 'application/json'})
      JSON.parse(res.body)['id']
    rescue => e
      Rails.logger.warn "#{self}##{__method__}: #{e.class} #{e.message} #{url.inspect}"
      url
    end
  end
end