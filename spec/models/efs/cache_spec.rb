require 'rails_helper'

RSpec.describe Efs::Cache do
  let(:client) { spy('client') }
  let(:instance) { described_class.new('key_prefix', 'klass') }

  before do
    instance.instance_variable_set(:@client, client)
  end

  describe '#delete_object' do
    it do
      expect(client).to receive(:delete).with('key_prefix:1')
      instance.delete_object(1)
    end
  end
end
