require 'google/apis/urlshortener_v1'

class GoogleUrlshortenerClient

  KEY = ENV['URL_SHORTENER_KEY']

  def initialize
    @urlshortener = Google::Apis::UrlshortenerV1::UrlshortenerService.new
    @urlshortener.key = KEY
  end

  # {
  #   id: short_url,
  #   long_url: long_url,
  #   analytics: {
  #     all_time: {
  #       browsers: [{count: count, id: id}, ...],
  #       countries: [...],
  #       long_url_clicks: count,
  #       platforms: [...],
  #       referrers: [...],
  #       short_url_clicks: count
  #     },
  #     day: {...},
  #     month: {...},
  #     two_hours: {...},
  #     week: {...}
  #   }
  # }
  def get_url(url)
    @urlshortener.get_url(url, projection: 'FULL')
  end

  def insert_url(url)
    @urlshortener.insert_url(Google::Apis::UrlshortenerV1::Url.from_json({longUrl: url}.to_json)).id
  end

  def list_urls
    @urlshortener.list_urls(projection: 'FULL')
  end
end
