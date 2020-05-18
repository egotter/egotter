require 'rails_helper'

RSpec.describe UnfollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:client) { double('twitter') }
  let(:request) { described_class.new(user: user, uid: 1) }

  before { allow(request).to receive(:client).and_return(client) }

  describe '#perform!' do
    subject { request.perform! }

    before { allow(request).to receive(:error_check!) }

    it do
      expect(request.client).to receive(:unfollow).with(1)
      subject
    end

    context 'Twitter::Error::Unauthorized is raised' do
      before { allow(request.client).to receive(:unfollow).with(1).and_raise(Twitter::Error::Unauthorized) }
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'Twitter::Error::Forbidden is raised' do
      before { allow(request.client).to receive(:unfollow).with(1).and_raise(Twitter::Error::Forbidden) }

      context 'temporarily_locked? returns true' do
        let(:status) { instance_double(AccountStatus) }
        before do
          allow(AccountStatus).to receive(:new).with(anything).and_return(status)
          allow(status).to receive(:temporarily_locked?).and_return(true)
        end
        it { expect { subject }.to raise_error(described_class::TemporarilyLocked) }
      end
    end
  end

  describe '#error_check!' do
    subject { request.error_check! }

    context 'logs.size == 5' do
      before { allow(request).to receive_message_chain(:logs, :size).and_return(5) }
      it { expect { subject }.to raise_error(described_class::TooManyRetries) }
    end

    context 'finished? returns true' do
      before { allow(request).to receive(:finished?).and_return(true) }
      it { expect { subject }.to raise_error(described_class::AlreadyFinished) }
    end

    context 'unauthorized? returns true' do
      before do
        allow(request).to receive(:finished?).and_return(false)
        allow(request).to receive(:unauthorized?).and_return(true)
      end
      it { expect { subject }.to raise_error(described_class::Unauthorized) }
    end

    context 'from_uid == to_uid' do
      before do
        allow(request).to receive(:finished?).and_return(false)
        allow(request).to receive(:unauthorized?).and_return(false)
        request.uid = user.uid
      end
      it { expect { subject }.to raise_error(described_class::CanNotUnfollowYourself) }
    end

    context 'not_found? returns true' do
      before do
        allow(request).to receive(:finished?).and_return(false)
        allow(request).to receive(:unauthorized?).and_return(false)
        allow(request).to receive(:not_found?).and_return(true)
      end
      it { expect { subject }.to raise_error(described_class::NotFound) }
    end

    context "friendship? returns false" do
      before do
        allow(request).to receive(:finished?).and_return(false)
        allow(request).to receive(:unauthorized?).and_return(false)
        allow(request).to receive(:not_found?).and_return(false)
        allow(request).to receive(:friendship?).and_return(false)
      end
      it { expect { subject }.to raise_error(described_class::NotFollowing) }
    end
  end

  describe '.finished' do
    subject { described_class.finished(user_id: user.id, created_at: time) }
    let(:user) { create(:user) }
    let!(:time) { Time.zone.now }

    let!(:req1) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time - 1.second,  error_class: 'Error') }
    let!(:req2) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time - 1.second,  error_class: '') }
    let!(:req3) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time - 1.second,  error_class: 'Error') }
    let!(:req4) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time - 1.second,  error_class: '') }
    let!(:req5) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time + 1.second, error_class: 'Error') }
    let!(:req6) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time + 1.second, error_class: '') }
    let!(:req7) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time + 1.second, error_class: 'Error') }
    let!(:req8) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time + 1.second, error_class: '') }

    it { is_expected.to match_array([req6]) }
  end

  describe '.unprocessed' do
    let(:subject) { described_class.unprocessed(user_id: user.id, created_at: time) }
    let(:user) { create(:user) }
    let!(:time) { Time.zone.now }

    let!(:req1) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time - 1.second,  error_class: 'Error') }
    let!(:req2) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time - 1.second,  error_class: '') }
    let!(:req3) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time - 1.second,  error_class: 'Error') }
    let!(:req4) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time - 1.second,  error_class: '') }
    let!(:req5) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time + 1.second, error_class: 'Error') }
    let!(:req6) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: Time.zone.now, created_at: time + 1.second, error_class: '') }
    let!(:req7) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time + 1.second, error_class: 'Error') }
    let!(:req8) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time + 1.second, error_class: '') }
    let!(:req9) { described_class.create!(user_id: user.id, uid: user.uid, finished_at: nil,           created_at: time + 1.second, error_class: '') }

    before { req8.logs.create }

    it { is_expected.to match_array([req9]) }
  end
end
