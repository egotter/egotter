require 'rails_helper'

RSpec.describe CreateMuteReportWorker do
  let(:user) { create(:user, with_settings: true) }
  let(:worker) { described_class.new }

  before do
    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  describe '#perform' do
    subject { worker.perform(user.id) }

    before do
      create(:muting_relationship, from_uid: 1, to_uid: user.uid)
    end

    context '#has_valid_subscription? returns true' do
      before { allow(user).to receive(:has_valid_subscription?).and_return(true) }
      it do
        expect(user).not_to receive(:following_egotter?)
        expect(PeriodicReport).not_to receive(:access_interval_too_long?)
        expect(MuteReport).to receive(:you_are_muted).with(user.id, requested_by: nil)
        subject
      end
    end

    context '#has_valid_subscription? returns false' do
      before { allow(user).to receive(:has_valid_subscription?).and_return(false) }
      it do
        expect(user).to receive(:following_egotter?).and_return(true)
        expect(PeriodicReport).to receive(:access_interval_too_long?).with(user).and_return(false)
        expect(MuteReport).to receive(:you_are_muted).with(user.id, requested_by: nil)
        subject
      end
    end
  end
end