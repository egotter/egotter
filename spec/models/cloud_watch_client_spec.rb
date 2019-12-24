require 'rails_helper'

RSpec.describe CloudWatchClient, type: :model do
end

RSpec.describe CloudWatchClient::Metrics, type: :model do
  describe '#append' do
    let(:client) { described_class.new }
    let(:namespace) { 'namespace' }
    let(:name) { 'name' }
    let(:dimensions) { 'dimensions' }
    let(:value) { 'value' }
    let(:send_data) do
      {
          metric_name: name,
          dimensions: dimensions,
          timestamp: Time.zone.now,
          value: value,
          unit: 'Count'
      }
    end
    subject { client.append(name, value, namespace: namespace, dimensions: dimensions) }

    it do
      freeze_time do
        subject
        expect(client.instance_variable_get(:@metrics)).to match({namespace => [send_data]})
        expect(client.instance_variable_get(:@changed)).to be_truthy
      end
    end
  end

  describe '#update' do
    let(:client) { described_class.new }
    let(:internal_client) { client.instance_variable_get(:@client).instance_variable_get(:@client) }

    before do
      client.instance_variable_set(:@changed, true)
      client.instance_variable_set(:@metrics, {'key' => 'value'})
    end

    it do
      expect(internal_client).to receive(:put_metric_data).with({namespace: 'key', metric_data: 'value'})
      client.update
    end
  end

  describe '#logger' do
    it { expect(described_class.new.respond_to?(:logger)).to be_truthy }
  end
end

RSpec.describe CloudWatchClient::Dashboard, type: :model do
  describe '#logger' do
    it { expect(described_class.new('name').respond_to?(:logger)).to be_truthy }
  end
end
