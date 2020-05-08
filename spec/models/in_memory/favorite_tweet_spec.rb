require 'rails_helper'

RSpec.describe InMemory::FavoriteTweet do
  describe '.client' do
    subject { described_class.send(:client) }
    it do
      key_prefix = subject.instance_variable_get(:@key_prefix)
      expect(key_prefix).to include(described_class.name)
    end
  end
end
