require 'digest/md5'

module PageCachesHelper
  def page_cache_token(value)
    Digest::MD5.hexdigest("#{value}-#{ENV['PAGE_CACHE_TOKEN_SEED']}")
  end

  def verify_page_cache_token(hash, value)
    hash && (match = hash.match(/\A[0-9a-zA-Z]+\z/)) && match[0] == page_cache_token(value)
  end
end
