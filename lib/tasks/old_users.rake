namespace :old_users do
  desc 'create old_users'
  task create: :environment do
    ActiveRecord::Base.connection.execute('DROP TABLE IF EXISTS old_users')
    ActiveRecord::Base.connection.execute('CREATE TABLE old_users like users')
    ActiveRecord::Base.connection.execute('ALTER TABLE old_users DROP COLUMN authorized')
    ActiveRecord::Base.connection.execute("ALTER TABLE old_users ADD COLUMN authorized tinyint(1) NOT NULL DEFAULT '0'")
  end

  desc 'load old_users'
  task load: :environment do
    class OldUser < ActiveRecord::Base; end
    old_users =
      File.read('mongo2.json').split("\n").map do |line|
        json = JSON.parse(line)
        OldUser.new(uid: json['uid'], screen_name: '-1', secret: json['secret'], token: json['token'], email: '-1')
      end
    Rails.logger.silence do
      old_users.each_slice(5000).each { |ary| OldUser.import(ary, validate: false) }
    end
  end

  desc 'verify old_users'
  task verify: :environment do
    class OldUser < ActiveRecord::Base; end
    processed = Queue.new

    OldUser.find_in_batches(batch_size: 5000) do |old_users_array|
      clients = old_users_array.map { |user| ApiClient.instance(access_token: user.token, access_token_secret: user.secret, logger: Naught.build.new) }
      Parallel.each_with_index(clients, in_threads: 10) do |client, i|
        processed << {i: i, uid: (client.verify_credentials.id rescue nil)}
        print '.' if i % 10 == 0
      end
    end
    puts ''

    processed = processed.size.times.map { processed.pop }.sort_by { |r| r[:i] }
    authorized = processed.select { |r| r[:uid] }
    authorized.map { |a| a[:uid] }.each_slice(5000).each do |uids_array|
      OldUser.where(uid: uids_array).update_all(authorized: true)
    end
    puts "all: #{OldUser.all.size}, processed: #{processed.size}, authorized: #{authorized.size}"
  end

  desc 'find active old_users'
  task find_active: :environment do
    class OldUser < ActiveRecord::Base; end
    processed_count = 0
    active_count = 0

    OldUser.where(authorized: true).find_in_batches(batch_size: 5000) do |old_users_array|
      processed_count += old_users_array.size
      active_count += User.where(uid: old_users_array.map { |ou| ou.uid }).size
    end

    puts "all: #{OldUser.all.size}, processed: #{processed_count}, active: #{active_count}"
  end
end
