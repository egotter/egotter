require 'rails_helper'

RSpec.describe MutingRelationship, type: :model do
  describe '.update_all_mutes' do
    let(:user) { create(:user) }
    let(:uids) { [1, 2, 3, 5, 6] }
    let(:persisted_uids) { [1, 2, 3, 4, 5] }
    let(:importable_uids) { [6] }
    let(:deletable_uids) { [4] }
    subject { described_class.update_all_mutes(user) }
    before { persisted_uids.each { |uid| create(:muting_relationship, from_uid: user.uid, to_uid: uid) } }
    it do
      expect(described_class.pluck(:to_uid)).to eq(persisted_uids)
      expect(described_class).to receive(:collect_uids).with(user.id).and_return(uids)
      expect(described_class).to receive(:filter_additional_mutes).with(user.uid, uids).and_call_original
      expect(described_class).to receive(:import_mutes).with(user.uid, importable_uids).and_call_original
      expect(described_class).to receive(:filter_deletable_mutes).with(user.uid, uids).and_call_original
      expect(described_class).to receive(:delete_mutes).with(user.uid, deletable_uids).and_call_original
      subject
      expect(described_class.pluck(:to_uid)).to eq(uids)
    end
  end

  describe '.import_mutes' do
    let(:from_uid) { 1 }
    let(:to_uids) { (2..1500).to_a }
    subject { described_class.import_mutes(from_uid, to_uids) }
    it do
      expect { subject }.to change { described_class.all.size }.by(1499)
      subject
      expect(described_class.pluck(:from_uid, :to_uid)).to eq(to_uids.map { |to_uid| [from_uid, to_uid] })
    end
  end

  describe '.filter_additional_mutes' do
    let(:from_uid) { 1 }
    let(:to_uids) { [2, 3, 4] }
    subject { described_class.filter_additional_mutes(from_uid, to_uids) }

    context 'New uids' do
      it { is_expected.to eq([2, 3, 4]) }
    end

    context 'One has been persisted' do
      before { create(:muting_relationship, from_uid: from_uid, to_uid: 3) }
      it { is_expected.to eq([2, 4]) }
    end
  end

  describe '.filter_deletable_mutes' do
    let(:from_uid) { 1 }
    let(:to_uids) { [2, 3, 4] }
    subject { described_class.filter_deletable_mutes(from_uid, to_uids) }
    before { create(:muting_relationship, from_uid: from_uid, to_uid: 5) }
    it { is_expected.to eq([5]) }
  end

  describe '.delete_mutes' do
    let(:from_uid) { 1 }
    let(:to_uids) { [2, 3, 4] }
    subject { described_class.delete_mutes(from_uid, to_uids) }
    before { create(:muting_relationship, from_uid: from_uid, to_uid: 3) }
    it { expect { subject }.to change { described_class.all.size }.by(-1) }
  end

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
      allow(client).to receive(:muted_ids).with(anything).and_return(response)
    end
    it { is_expected.to eq([1, 2, 3]) }
  end
end
