require 'rails_helper'

RSpec.describe TwitterUser, type: :model do
  let(:tu) { build(:twitter_user) }

  let(:client) {
    client = Object.new

    def client.user?(*args)
      true
    end

    def client.user(*args)
      Hashie::Mash.new({id: 1, screen_name: 'sn'})
    end

    client
  }
end