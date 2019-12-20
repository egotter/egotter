require 'bundler/setup'

require 'active_support'
require 'active_support/encrypted_file'

class SecretFile < ActiveSupport::EncryptedFile
  def initialize(content_path, key_path: 'config/master.key', env_key: 'RAILS_MASTER_KEY')
    super content_path: content_path, key_path: key_path,
          env_key: env_key, raise_if_missing_key: true
  end

  class << self
    def read(path)
      new(path).read
    end

    def write(path, contents)
      new(path).write(contents)
    end
  end

  def read
    super
  rescue ActiveSupport::EncryptedFile::MissingContentError
    ''
  end
end
