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

  class << self
    def current_ids
      where(authorized: true, locked: false).pluck(:id)
    end

    def api_client(options = {})
      select(:token, :secret).find(current_ids.sample).api_client(options)
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
