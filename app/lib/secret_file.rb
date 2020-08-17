require 'fileutils'

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

    def edit(path, &block)
      contents = read(path)
      tmp_file = "#{File.basename(path)}.#{Process.pid}"
      tmp_path = File.join(Dir.tmpdir, tmp_file)
      IO.binwrite(tmp_path, contents)

      yield tmp_path

      updated_contents = IO.binread(tmp_path)
      write(path, updated_contents) if updated_contents != contents
    ensure
      FileUtils.rm(tmp_path) if File.exist?(tmp_path)
    end
  end

  def read
    super
  rescue ActiveSupport::EncryptedFile::MissingContentError
    ''
  end
end
