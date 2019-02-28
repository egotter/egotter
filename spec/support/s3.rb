module StoreToFile
  def dir
    d = Rails.root.join("tmp/s3_test/#{bucket_name}")
    FileUtils.mkdir_p(d) unless File.exists?(d)
    d
  end

  def store(twitter_user_id, body)
    File.write(File.join(dir, twitter_user_id.to_s), body)
  end

  def fetch(twitter_user_id)
    File.read(File.join(dir, twitter_user_id.to_s))
  rescue Errno::ENOENT => e
    raise unless e.message.start_with?('No such file or directory')
  end
end

S3::Friendship.send(:extend, StoreToFile)
S3::Followership.send(:extend, StoreToFile)
S3::Profile.send(:extend, StoreToFile)

TwitterDB::S3::Friendship.send(:extend, StoreToFile)
TwitterDB::S3::Followership.send(:extend, StoreToFile)
