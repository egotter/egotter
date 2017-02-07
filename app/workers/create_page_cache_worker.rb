class CreatePageCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: false, backtrace: false

  # A user agent of Net::HTTP is `Ruby`.
  def perform(uid)
    unless ::Cache::PageCache.new.exists?(uid)
      uri = URI.parse(Rails.application.routes.url_helpers.page_caches_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if Rails.env.production?
      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = {uid: uid, token: ENV['PAGE_CACHE_TOKEN']}.to_json
      http.request(request).body
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid}"
  end
end
