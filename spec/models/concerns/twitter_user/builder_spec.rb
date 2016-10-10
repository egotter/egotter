require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Builder do
  let(:user_id) { Random.rand(100) }

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

  describe '.build_by_user' do
    let(:user) { client.user('ts_3156') }
    let(:tu) { TwitterUser.build_by_user(user) }

    it 'returns TwitterUser' do
      expect(tu).to be_a_kind_of(TwitterUser)
      expect(tu.uid).to eq(user.id.to_s)
      expect(tu.screen_name).to eq(user.screen_name)
    end
  end

  describe '.build_with_relations' do
    let(:user) { client.user('ts_3156') }
    let(:tu) { TwitterUser.build_with_relations(user, client: client, login_user: User.find_by(id: user_id)) }

    it 'calls .build_by_user' do
      allow_any_instance_of(TwitterUser).to receive(:build_relations)
      expect(TwitterUser).to receive(:build_by_user).and_return(TwitterUser.new)
      tu
    end

    it 'calls #build_relations' do
      expect_any_instance_of(TwitterUser).to receive(:build_relations)
      tu
    end
  end
end