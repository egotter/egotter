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

  def api_client(options = {})
    ApiClient.instance(options.merge(access_token: token, access_token_secret: secret))
  end

  def sync_credential_status
    begin
      user = api_client.twitter.verify_credentials
      assign_attributes(authorized: true, screen_name: user.screen_name)
    rescue => e
      if TwitterApiStatus.unauthorized?(e)
        assign_attributes(authorized: false)
      elsif TwitterApiStatus.temporarily_locked?(e)
        assign_attributes(locked: true)
      else
        raise
      end
    end

    save! if changed?
  end

  class << self
    def current_ids
      where(authorized: true, locked: false).pluck(:id)
    end

    def api_client(options = {})
      select(:token, :secret).find(current_ids.sample).api_client(options)
    end

    def load(path)
      JSON.parse(File.read(path)).each do |bot|
        create!(uid: bot['uid'], screen_name: bot['screen_name'], secret: bot['secret'], token: bot['token'])
      end
    end

    def all_rate_limit
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
            follower_ids: p[:rate_limit].follower_ids,
            search: p[:rate_limit].search,
        }
      end
    end
  end
end
