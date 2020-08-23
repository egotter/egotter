class MessageEncryptor
  def initialize(key_path: 'config/master.key', env_key: 'RAILS_MASTER_KEY')
    key = ENV[env_key] || File.binread(key_path).strip
    @encryptor = ActiveSupport::MessageEncryptor.new([key].pack("H*"), cipher: 'aes-128-gcm')
  end

  def encrypt(contents)
    @encryptor.encrypt_and_sign contents
  end

  def decrypt(contents)
    @encryptor.decrypt_and_verify contents
  end
end
