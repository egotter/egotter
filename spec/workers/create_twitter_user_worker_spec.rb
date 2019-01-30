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

  describe '#save_twitter_db_user' do
    subject { described_class.new.save_twitter_db_user(twitter_user) }

    context 'Without persisted record' do
      it 'saves TwitterDB::User' do
        expect(TwitterDB::User.exists?(uid: twitter_user.uid)).to be_falsey
        subject

        twitter_db_user = TwitterDB::User.find_by(uid: twitter_user.uid)
        expect(twitter_db_user.screen_name).to eq(twitter_user.screen_name)
        expect(twitter_db_user.friends_size).to eq(-1)
        expect(twitter_db_user.followers_size).to eq(-1)
      end
    end

    context 'With persisted record' do
      let(:friends_size) { 5 }
      let(:followers_size) { 10 }
      let(:twitter_db_user) do
        create(:twitter_db_user, uid: twitter_user.uid, screen_name: twitter_user.screen_name,
               friends_size: friends_size, followers_size: followers_size)
      end
      before { twitter_db_user.save! }
      it 'updates TwitterDB::User' do
        expect(twitter_db_user.persisted?).to be_truthy
        subject

        expect(twitter_db_user.screen_name).to eq(twitter_user.screen_name)
        expect(twitter_db_user.friends_size).to eq(friends_size)
        expect(twitter_db_user.followers_size).to eq(followers_size)
      end
    end
  end
end
