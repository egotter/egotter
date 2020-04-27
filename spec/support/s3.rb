[
    S3::Friendship,
    S3::Followership,
    S3::Profile
].each do |klass|
  klass.instance_variable_set(:@client, Aws::S3::Client.new(stub_responses: true))
end

module S3
  module Testing
    def initialize(*args)
      super
      @s3 = Aws::S3::Client.new(stub_responses: true)
    end
  end
end

S3::Client.prepend(S3::Testing)
