require 'rails_helper'

RSpec.describe UnfollowRequest, type: :model do
  let(:user) { create(:user) }
  let(:request) { described_class.new(user: user, uid: 1) }

  describe '#perform!' do
    let(:client) { ApiClient.instance.twitter }
    subject { request.perform! }
    let(:from_uid) { user.uid }
    let(:to_uid) { request.uid }

    before do
      allow(request).to receive(:client).with(no_args).and_return(client)
      allow(request).to receive(:unauthorized?).with(no_args).and_return(false)
    end

    it 'calls client#unfollow' do
      allow(client).to receive(:user?).with(to_uid).and_return(true)
      allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(true)
      expect(client).to receive(:unfollow).with(to_uid)
      subject
    end

    context 'from_uid == to_uid' do
      before { request.uid = user.uid }
      it do
        expect { subject }.to raise_error(UnfollowRequest::CanNotUnfollowYourself)
      end
    end

    context 'User not found.' do
      before { allow(client).to receive(:user?).with(to_uid).and_return(false) }
      it do
        expect { subject }.to raise_error(UnfollowRequest::NotFound)
      end
    end

    context "You haven't followed the user." do
      before do
        allow(client).to receive(:user?).with(to_uid).and_return(true)
        allow(client).to receive(:friendship?).with(from_uid, to_uid).and_return(false)
      end
      it do
        expect { subject }.to raise_error(UnfollowRequest::NotFollowing)
      end
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
