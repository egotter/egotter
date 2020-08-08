class MessageEncryptor
  def initialize
    secret = [File.read('config/master.key')].pack("H*")
    @encryptor = ActiveSupport::MessageEncryptor.new(secret, cipher: 'aes-128-gcm')
  end

  def encrypt(contents)
    @encryptor.encrypt_and_sign contents
  end

  def decrypt(contents)
    @encryptor.decrypt_and_verify contents
  end
end
