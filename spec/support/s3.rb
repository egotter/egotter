module StoreToFile
  def store(twitter_user_id, body)
    dir = Rails.root.join("tmp/s3/#{bucket_name}")
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    File.write(File.join(dir, twitter_user_id.to_s), body)
  end

  def fetch(twitter_user_id)
    File.read(File.join(Rails.root.join("tmp/s3/#{bucket_name}"), twitter_user_id.to_s))
  end
end

S3::Friendship.send(:extend, StoreToFile)
S3::Followership.send(:extend, StoreToFile)
