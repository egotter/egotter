require 'rails_helper'

RSpec.describe AssembleTwitterUserRequest, type: :model do
  let(:user) { create(:user) }
  let(:twitter_user) { create(:twitter_user, user_id: user.id) }
  let(:request) { described_class.create!(twitter_user: twitter_user) }

  before do
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
  end

  describe '#perform!' do
    subject { request.perform! }
    it do
      expect(request).to receive(:first_part).with(user.id, twitter_user.uid)
      expect(request).to receive(:second_part)
      subject
    end
  end

  describe '#first_part' do
    subject { request.perform! }

    it do
      expect(UpdateUsageStatWorker).to receive(:perform_async).with(twitter_user.uid, user_id: twitter_user.user_id, location: described_class)
      expect(CreateFriendInsightWorker).to receive(:perform_async).with(twitter_user.uid, anything)
      expect(CreateFollowerInsightWorker).to receive(:perform_async).with(twitter_user.uid, anything)
      expect(CreateTopFollowerWorker).to receive(:perform_async).with(twitter_user.id)
      expect(CreateTwitterUserCloseFriendsWorker).to receive(:perform_async).with(twitter_user.id)
      subject
    end
  end

  describe '#second_part' do
    subject { request.send(:second_part) }

    it do
      expect(CreateTwitterUserOneSidedFriendsWorker).to receive(:perform_async).with(twitter_user.id)
      expect(CreateTwitterUserInactiveFriendsWorker).to receive(:perform_async).with(twitter_user.id)
      expect(CreateTwitterUserUnfriendsWorker).to receive(:perform_async).with(twitter_user.id)
      expect(twitter_user).to receive(:update).with(any_args)
      subject
    end
  end

  describe '#validate_record_creation_order!' do
    subject { request.send(:validate_record_creation_order!) }

    it { is_expected.to be_truthy }

    context 'The twitter_user is not up to date' do
      before { build(:twitter_user, uid: twitter_user.uid).save(validate: false) }
      it do
        is_expected.to be_falsey
        expect(request.status).to eq('not_latest')
      end
    end

    context 'The assembled_at is present' do
      before { twitter_user.update(assembled_at: Time.zone.now) }
      it do
        is_expected.to be_falsey
        expect(request.status).to eq('already_assembled')
      end
    end
  end

  describe '#validate_record_friends!' do
    subject { request.send(:validate_record_friends!) }

    it { is_expected.to be_truthy }

    context '#too_little_friends? returns true' do
      before { allow(twitter_user).to receive(:too_little_friends?).and_return(true) }
      it do
        is_expected.to be_falsey
        expect(request.status).to eq('too_little_friends')
      end
    end

    context '#no_need_to_import_friendships? returns true' do
      before { allow(twitter_user).to receive(:no_need_to_import_friendships?).and_return(true) }
      it do
        is_expected.to be_falsey
        expect(request.status).to eq('no_need_to_import')
      end
    end
  end
end
