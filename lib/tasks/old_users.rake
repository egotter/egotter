namespace :old_users do
  desc 'create'
  task create: :environment do
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS old_users')
    ActiveRecord::Base.connection.execute('CREATE TABLE old_users like users')
    ActiveRecord::Base.connection.execute('ALTER TABLE old_users DROP INDEX index_users_on_uid')
    ActiveRecord::Base.connection.execute('ALTER TABLE old_users ADD UNIQUE index_users_on_uid (uid)')
    ActiveRecord::Base.connection.execute('ALTER TABLE old_users ADD COLUMN authorized bool AFTER id')
  end

  desc 'load'
  task load: :environment do
    class OldUser < ActiveRecord::Base; end
    File.read('mongo2.json').split("\n").map do |line|
      json = JSON.parse(line)
      OldUser.create!(uid: json['uid'], screen_name: '-1', secret: json['secret'], token: json['token'], email: '-1')
    end
  end

  desc 'verify'
  task verify: :environment do
    class OldUser < ActiveRecord::Base; end
    processed = Queue.new
    clients = OldUser.all.map { |user| ApiClient.instance(access_token: user.token, access_token_secret: user.secret, logger: Naught.build.new) }
    Parallel.each_with_index(clients, in_threads: 10) do |client, i|
      processed << {i: i, uid: (client.verify_credentials.id rescue nil)}
      print '.'
    end
    puts ''

    success = processed.size.times.map { processed.pop }.sort_by { |p| p[:i] }.select { |r| r[:uid] }
    success.each { |s| OldUser.find_by(uid: s[:uid]).update(authorized: true) }
    puts "OK #{success.size}, NG: #{OldUser.all.size - success.size}"
  end
end
