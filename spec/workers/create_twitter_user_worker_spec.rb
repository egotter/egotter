require 'rails_helper'

RSpec.describe CreateTwitterUserWorker do
  let(:twitter_user) { build(:twitter_user) }

  describe '#build_twitter_user' do
    subject { described_class.new.build_twitter_user(nil, nil, nil, builder: builder) }
    let(:builder) { TwitterUser.builder(nil) }
    before { allow(builder).to receive(:build).and_return(twitter_user) }

    it 'returns TwitterUser' do
      is_expected.to equal(twitter_user)
    end

    context 'With invalid attr' do
      before do
        allow(twitter_user).to receive(:invalid?).and_return(true)
        twitter_user.errors[:base] << 'Something error'
      end

      it 'raises Job::Error::RecordInvalid' do
        expect { subject }.to raise_error(Job::Error::RecordInvalid, twitter_user.errors.full_messages.join(', '))
      end
    end
  end

  describe '#save_twitter_user' do
    subject { described_class.new.save_twitter_user(twitter_user) }

    it 'saves TwitterUser' do
      subject
      expect(twitter_user.persisted?).to be_truthy
    end

    context 'With invalid attr' do
      before do
        allow(twitter_user).to receive(:save).and_return(false)
        twitter_user.errors[:base] << 'Something error'
      end

      context 'With persisted record' do
        before { create(:twitter_user, uid: twitter_user.uid) }
        it 'raises Job::Error::NotChanged' do
          expect(TwitterUser.exists?(uid: twitter_user.uid)).to be_truthy
          expect { subject }.to raise_error(Job::Error::NotChanged, 'Not changed')
        end
      end

      context 'Without persisted record' do
        it 'raises Job::Error::RecordInvalid' do
          expect(TwitterUser.exists?(uid: twitter_user)).to be_falsey
          expect { subject }.to raise_error(Job::Error::RecordInvalid, twitter_user.errors.full_messages.join(', '))
        end
      end
    end
  end
end
