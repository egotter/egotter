# == Schema Information
#
# Table name: bots
#
#  id          :integer          not null, primary key
#  uid         :bigint(8)        not null
#  screen_name :string(191)      not null
#  authorized  :boolean          default(TRUE), not null
#  secret      :string(191)      not null
#  token       :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bots_on_screen_name  (screen_name)
#  index_bots_on_uid          (uid) UNIQUE
#

class Bot < ApplicationRecord
  include Concerns::User::ApiAccess

  class << self
    def current_ids
      where(authorized: true).pluck(:id)
    end

    def api_client
      find(current_ids.sample).api_client
    end

    def load(path)
      JSON.parse(File.read(path)).each do |bot|
        create!(uid: bot['uid'], screen_name: bot['screen_name'], secret: bot['secret'], token: bot['token'])
      end
    end

    def verify_credentials
      processed = Queue.new
      Parallel.each(all, in_threads: 10) do |bot|
        authorized = true
        locked = false

        begin
          bot.api_client.verify_credentials
        rescue => e
          if AccountStatus.unauthorized?(e)
            authorized = false
          elsif AccountStatus.temporarily_locked?(e)
            locked = true
          else
            raise
          end
        end
        processed << {id: bot.id, screen_name: bot.screen_name, authorized: authorized, locked: locked}
      end

      processed.size.times.map { processed.pop }.sort_by { |p| p[:id] }
    end

    def rate_limit
      processed = Queue.new
      Parallel.each(all, in_threads: 10) do |bot|
        processed << {id: bot.id, rate_limit: bot.rate_limit}
      end

      processed.size.times.map { processed.pop }.sort_by { |p| p[:id] }.map do |p|
        {
            id: p[:id],
            verify_credentials: p[:rate_limit].verify_credentials,
            users: p[:rate_limit].users,
            friend_ids: p[:rate_limit].friend_ids,
            follower_ids: p[:rate_limit].follower_ids
        }
      end
    end
  end
end
