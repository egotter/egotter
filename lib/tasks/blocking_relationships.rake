namespace :blocking_relationships do
  desc 'Import'
  task import: :environment do
    sigint = Sigint.new.trap
    stopped = false

    # Avoid circular dependency
    ApiClient
    CacheDirectory

    green = -> (str) { print "\e[32m#{str}\e[0m" }
    red = -> (str) { print "\e[31m#{str}\e[0m" }
    start = ENV['START'] ? ENV['START'].to_i : 1
    debug = ENV['DEBUG']

    User.authorized.where(locked: false).find_in_batches(start: start, batch_size: 1000) do |users|
      Parallel.each(users, in_threads: 10) do |user|
        next if BlockingRelationship.exists?(from_uid: user.uid)

        begin
          blocked_ids = user.api_client.twitter.blocked_ids(count: 5000).attrs[:ids]
          BlockingRelationship.import_from(user.uid, blocked_ids)
        rescue => e
          if AccountStatus.invalid_or_expired_token?(e) ||
              AccountStatus.temporarily_locked?(e)
            red.call('.')
            if debug
              puts "#{e.inspect} user_id=#{user.id}"
            end
          else
            stopped = true
            raise Parallel::Break
          end
        end
      end

      green.call('.')

      if stopped || sigint.trapped?
        puts "\nLast user_id #{users[-1].id}"
        break
      end
    end
  end
end
