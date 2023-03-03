# == Schema Information
#
# Table name: bots
#
#  id          :integer          not null, primary key
#  uid         :bigint(8)        not null
#  screen_name :string(191)      not null
#  enabled     :boolean          default(TRUE), not null
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

  def rate_limit
    result = super
    {
        id: id,
        verify_credentials: result.verify_credentials,
        users: result.users,
        friend_ids: result.friend_ids,
        follower_ids: result.follower_ids,
        search: result.search,
    }
  end

  def invalidate_credentials
    user = api_client.twitter.verify_credentials
    assign_attributes(authorized: true, screen_name: user.screen_name)

    if changed?
      save
      SlackBotClient.channel('monit_bot').post_message("Bot is updated id=#{id} changes=#{saved_changes.except('updated_at')}")
    end
  rescue => e
    if TwitterApiStatus.retry_timeout?(e)
      # Do nothing
    elsif TwitterApiStatus.unauthorized?(e)
      update(authorized: false)
    elsif TwitterApiStatus.temporarily_locked?(e)
      update(locked: true)
    else
      Airbag.exception e, bot_id: id
    end
  end

  class << self
    def available_ids
      where(enabled: true, authorized: true, locked: false).pluck(:id)
    end

    def agent
      select(:token, :secret).find(available_ids.sample)
    end

    # TODO Remove later
    def api_client(options = {})
      agent.api_client(options)
    end

    def load(path = 'bots.json')
      JSON.parse(File.read(path)).each do |bot|
        create!(uid: bot['uid'], screen_name: bot['screen_name'], secret: bot['secret'], token: bot['token'])
      end
    end

    def dump(path = 'bots.json')
      data = all.map { |b| {uid: b.uid, screen_name: b.screen_name, secret: b.secret, token: b.token} }
      File.write(path, data.to_json)
    end
  end
end
