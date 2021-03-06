require 'rails_helper'

RSpec.describe CreateSearchRequestWorker do
  let(:screen_name) { 'name' }
  let(:worker) { described_class.new }

  describe '#after_expire' do
    subject { worker.after_expire(screen_name) }
    it { is_expected.to be_truthy }
  end

  describe '#perform' do
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
