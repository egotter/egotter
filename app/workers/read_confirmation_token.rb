class ReadConfirmationToken
  class << self
    def generate
      SecureRandom.urlsafe_base64(10)
    end
  end
end
