require 'digest/md5'

module CachesHelper
  def update_hash(value)
    Digest::MD5.hexdigest("#{value}-#{ENV['SEED']}").slice(0, 20)
  end
end
