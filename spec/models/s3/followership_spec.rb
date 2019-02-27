require 'rails_helper'

RSpec.describe S3::Followership do
  let(:client) { described_class.client }

  describe '.store' do
    it do
      expect(client).to_not receive(:put_object)
      described_class.store(1, 'body')
    end
  end

  describe '.fetch' do
    it do
      expect(client).to_not receive(:get_object)
      described_class.fetch(1)
    end
  end
end
