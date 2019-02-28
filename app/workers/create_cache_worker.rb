class CreateCacheWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(values)
    ApplicationRecord.benchmark("#{self.class} Create cache #{values}", level: :debug) do
      do_perform(values)
    end
  end

  def do_perform(values)
    user_id = values['user_id']
    user = User.select(:id, :uid, :screen_name, :token, :secret).find(user_id)
    threads = []

    TwitterUser.select(:id).where(uid: user.uid).order(created_at: :desc).each do |twitter_user|
      [S3::Friendship, S3::Followership, S3::Profile].each do |klass|
        threads << Proc.new {klass.find_by(twitter_user_id: twitter_user.id)}
      end
    end

    # twitter_db_user = TwitterDB::User.select(:id).find_by(uid: user.uid)
    [TwitterDB::S3::Friendship, TwitterDB::S3::Followership, TwitterDB::S3::Profile].each do |klass|
      threads << Proc.new do
        klass.delete_cache_by(uid: user.uid)
        klass.find_by(uid: user.uid)
      end
    end

    client = user.api_client
    threads << Proc.new {client.user}
    threads << Proc.new {client.user(user.uid)}
    threads << Proc.new {client.user(user.screen_name)}

    Parallel.each(threads, in_threads: 3, &:call)
  end
end
