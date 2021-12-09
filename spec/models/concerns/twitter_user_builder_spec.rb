require 'rails_helper'

RSpec.describe TwitterUserBuilder do
  let(:klass) do
    Class.new do
      include TwitterUserBuilder
      attr_accessor :uid, :screen_name, :friends_count, :followers_count, :profile_text

      def initialize(options)
        options.each { |k, v| instance_variable_set(:"@#{k}", v) }
      end
    end
  end

  describe '.from_api_user' do
    let(:user) { {id: 1, screen_name: 'sn', friends_count: 123, followers_count: 456} }
    subject { klass.from_api_user(user) }
    before { allow(klass).to receive(:filter_save_keys).with(user).and_return('filtered') }
    it do
      result = subject
      expect(result.uid).to eq(user[:id])
      expect(result.screen_name).to eq(user[:screen_name])
      expect(result.friends_count).to eq(user[:friends_count])
      expect(result.followers_count).to eq(user[:followers_count])
      expect(result.profile_text).to eq('filtered')
    end
  end

  describe '.filter_save_keys' do
    let(:hash) { {'id' => 1, 'name' => 'name', 'hello' => 'ok'} }
    subject { klass.send(:filter_save_keys, hash) }
    it { is_expected.to eq(hash.slice('id', 'name').to_json) }
  end
end