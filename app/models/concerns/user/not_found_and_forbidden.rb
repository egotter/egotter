require 'active_support/concern'

module Concerns::User::NotFoundAndForbidden
  extend ActiveSupport::Concern

  class_methods do
    def update_uid_batch
      sigint = Util::Sigint.new.trap

      # Avoid circular dependency
      Bot
      ApiClient

      green = -> (str) {print "\e[32m#{str}\e[0m"}
      red = -> (str) {print "\e[31m#{str}\e[0m"}
      start = ENV['START'] ? ENV['START'].to_i : 1

      batch_size = 500
      each_slice = 100

      self.where(uid: nil).find_in_batches(start: start, batch_size: batch_size) do |users|
        Parallel.each(users.each_slice(each_slice), in_threads: batch_size / each_slice) do |users_array|
          begin
            t_users = Bot.api_client.users(users_array.pluck(:screen_name))
            t_users.each do |t_user|
              user = users_array.find {|u| u.screen_name == t_user[:screen_name]}
              if user
                user.uid = t_user[:id]
                green.call('.')
              else
                red.call('.')
              end
            end
          rescue Twitter::Error::NotFound => e
            if e.message == 'No user matches for specified terms.'
              puts "#{e.class} #{e.message}"
            else
              raise
            end
          rescue Twitter::Error::ServiceUnavailable => e
            puts "#{e.class} #{e.message}"
            retry
          rescue => e
            raise
          end
        end

        puts "\n"

        changed = users.select(&:uid_changed?)
        if changed.any?
          puts "Import uid_changed #{changed.size}"
          Rails.logger.silence {self.import(changed, on_duplicate_key_update: %i(uid screen_name), validate: false)}
        end

        puts "Last id #{users[-1].id}"

        break if sigint.trapped?
      end
    end
  end
end