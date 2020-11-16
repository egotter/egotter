# == Schema Information
#
# Table name: bots
#
#  id          :integer          not null, primary key
#  uid         :bigint(8)        not null
#  screen_name :string(191)      not null
#  authorized  :boolean          default(TRUE), not null
#  locked      :boolean          default(FALSE), not null
#  secret      :string(191)      not null
#  token       :string(191)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_bots_on_authorized_and_locked  (authorized,locked)
#  index_bots_on_screen_name            (screen_name)
#  index_bots_on_uid                    (uid) UNIQUE
#

class Bot < ApplicationRecord
  include CredentialsApi

  class << self
    def current_ids
      where(authorized: true, locked: false).pluck(:id)
    end

    def api_client
      select(:token, :secret).find(current_ids.sample).api_client
    end

    def load(path)
      JSON.parse(File.read(path)).each do |bot|
        create!(uid: bot['uid'], screen_name: bot['screen_name'], secret: bot['secret'], token: bot['token'])
      end
    end

    def invalidate_expired_credentials
      verify_credentials.each do |cred|
        bot = find(cred[:id])
        bot.screen_name = cred[:screen_name]
        bot.authorized = cred[:authorized]
        bot.locked = cred[:locked]

        if bot.changed?
          bot.save!

          message = "bot is changed #{bot.saved_changes}"
          SlackClient.bot.send_message(message)
          logger.warn message
        end
      end
    end

    def verify_credentials
      processed = Queue.new

      all.each do |bot|
        screen_name = bot.screen_name
        suspended = nil
        authorized = true
        locked = false

        begin
          cred = bot.api_client.verify_credentials
          screen_name = cred[:screen_name]
          suspended = cred[:suspended]
          bot.api_client.users([bot.id])
        rescue => e
          if TwitterApiStatus.unauthorized?(e)
            authorized = false
          elsif TwitterApiStatus.temporarily_locked?(e)
            locked = true
          elsif TwitterApiStatus.no_user_matches?(e)
            # Do nothing
          else
            raise
          end
        end
        processed << {id: bot.id, uid: bot.uid, screen_name: screen_name, suspended: suspended, authorized: authorized, locked: locked}
      end

      processed.size.times.map { processed.pop }.sort_by { |p| p[:id] }
    end

    def rate_limit
      processed = Queue.new
      current_ids.each do |id|
        bot = Bot.find(id)
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
