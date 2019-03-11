require 'active_support/concern'

module Concerns::User::NotFoundAndForbidden
  extend ActiveSupport::Concern

  class_methods do
    def update_uid_batch
      sigint = Util::Sigint.new.trap

      # Avoid circular dependency
      Bot
      ApiClient

      start = ENV['START'] ? ENV['START'].to_i : 1

      batch_size = 500
      each_slice = 100

      where(uid: nil).find_in_batches(start: start, batch_size: batch_size) do |users|
        Parallel.each(users.each_slice(each_slice), in_threads: batch_size / each_slice) do |users_array|
          Batch.new(users_array).perform
        end

        changed = users.select(&:uid_changed?)
        if changed.any?
          puts "Import uid_changed #{changed.size}"
          Rails.logger.silence {import(changed, on_duplicate_key_update: %i(uid screen_name), validate: false)}
        end

        puts "Last id #{users[-1].id}"

        break if sigint.trapped?
      end
    end
  end

  class Batch
    def initialize(users)
      @users = users
    end

    def perform
      fetch_users(@users.pluck(:screen_name)).each do |t_user|
        user = @users.find {|u| u.screen_name == t_user[:screen_name]}
        user.uid = t_user[:id] if user
      end
    end

    def fetch_users(screen_names)
      client.users(screen_names)
    rescue Twitter::Error::NotFound => e
      if e.message == 'No user matches for specified terms.'
        puts "#{e.class} #{e.message}"
        []
      else
        raise
      end
    rescue Twitter::Error::ServiceUnavailable => e
      puts "#{e.class} #{e.message}"
      retry
    rescue => e
      raise
    end

    def client
      @client ||= Bot.api_client
    end
  end
end