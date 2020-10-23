require 'rails_helper'

RSpec.describe CreateSearchRequestWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:screen_name) { 'name' }
    let(:client) { double('client') }
    subject { worker.perform(screen_name) }
    before { allow(Bot).to receive(:api_client).and_return(client) }
    it do
      expect(client).to receive(:user).with(screen_name).and_return({id: 1})
      expect(SearchRequest).to receive_message_chain(:new, :write).with(screen_name)
      expect(client).to receive(:user).with(1)
      subject
    end
  end
end
