require 'rails_helper'

RSpec.describe EgotterFollower, type: :model do
  describe '.collect_uids' do
    let(:ids) { [1, 2, 3] }
    let(:response) { double('Response', attrs: {ids: ids, next_cursor: 0}) }
    let(:client) { double('Client') }
    subject { described_class.collect_uids }
    before do
      allow(Bot).to receive_message_chain(:api_client, :twitter).and_return(client)
      allow(client).to receive(:follower_ids).with(any_args).and_return(response)
    end
    it { is_expected.to eq(ids) }
  end

  describe '.import_uids' do
    subject { described_class.import_uids([1, 2]) }
    it { expect { subject }.to change { described_class.all.size }.by(2) }
  end

  describe '.filter_unnecessary_uids' do
    subject { described_class.filter_unnecessary_uids([2, 3]) }
    before { create(:egotter_follower, uid: 1) }
    it { is_expected.to eq([1]) }
  end

  describe '.delete_uids' do
    subject { described_class.delete_uids([1, 2]) }
    before { create(:egotter_follower, uid: 1) }
    it { expect { subject }.to change { described_class.all.size }.by(-1) }
  end
end
