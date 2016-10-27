require 'digest/md5'

module PageCachesHelper
  def page_cache_token(value)
    Digest::MD5.hexdigest("#{value}-#{ENV['SEED']}")
  end

  def verity_page_cache_token(hash, value)
    hash && (match = hash.match(/\A[0-9a-zA-Z]+\z/)) && match[0] == page_cache_token(value)
  end
end
