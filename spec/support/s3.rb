module StoreToFile
  def dir
    d = Rails.root.join("tmp/s3_test/#{bucket_name}")
    FileUtils.mkdir_p(d) unless File.exists?(d)
    d
  end

  def store(key, body)
    raise 'key is nil' if key.nil?
    File.write(File.join(dir, key.to_s), body)
  end

  def fetch(key)
    raise 'key is nil' if key.nil?
    File.read(File.join(dir, key.to_s))
  rescue Errno::ENOENT => e
    raise unless e.message.start_with?('No such file or directory')
  end
end

[
    S3::Friendship,
    S3::Followership,
    S3::Profile
].each do |klass|
  klass.send(:extend, StoreToFile)
end
