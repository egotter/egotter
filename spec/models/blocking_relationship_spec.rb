require 'rails_helper'

RSpec.describe BlockingRelationship, type: :model do
  describe '.import_from' do
    subject { described_class.import_from(1, [2, 3]) }
    it { expect { subject }.to change { described_class.all.size }.by(2) }
  end

  describe '.collect_uids' do
    let(:user) { create(:user) }
    let(:client) { double('client') }
    let(:response) { double('response', attrs: {ids: [1, 2, 2, 3], next_cursor: 0}) }
    subject { described_class.collect_uids(user.id) }
    before do
      allow(User).to receive(:find).with(user.id).and_return(user)
      allow(user).to receive_message_chain(:api_client, :twitter).and_return(client)
      allow(client).to receive(:blocked_ids).with(anything).and_return(response)
    end
    it { is_expected.to eq([1, 2, 3]) }
  end
end
