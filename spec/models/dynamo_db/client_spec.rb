require 'rails_helper'

RSpec.describe DynamoDB::Client do
  let(:dynamo_db) { double('dynamo_db') }
  let(:instance) { described_class.new('klass', 'table', 'partition_key') }
  let(:key) { 1 }

  before do
    instance.instance_variable_set(:@dynamo_db, dynamo_db)
    allow(instance).to receive(:db_key).with(key).and_return('key')
  end

  describe '#read' do
    subject { instance.read(key) }

    it do
      expect(dynamo_db).to receive(:get_item).with('key').and_return('output')
      is_expected.to eq('output')
    end
  end

  describe '#write' do
    subject { instance.write(key, 'input') }

    it do
      expect(dynamo_db).to receive(:put_item).with(table_name: 'table', item: 'input')
      subject
    end
  end

  describe '#delete' do
    subject { instance.delete(key) }

    it do
      expect(dynamo_db).to receive(:delete_item).with('key')
      subject
    end
  end
end
