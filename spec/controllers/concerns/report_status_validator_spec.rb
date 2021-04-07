require 'rails_helper'

describe ReportStatusValidator do
  let(:instance) { Object.new }
  let(:user) { create(:user) }

  before do
    instance.extend ReportStatusValidator
    allow(User).to receive(:find_by).with(uid: user.uid).and_return(user)
  end

  describe '#validate_report_status' do
    let(:uid) { user.uid }
    subject { instance.validate_report_status(uid) }

    before do
      allow(User).to receive(:find_by).with(uid: uid).and_return(user)
    end

    context 'user is not found' do
      before { allow(User).to receive(:find_by).with(uid: uid).and_return(nil) }
      it do
        expect(CreatePeriodicReportUnregisteredMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context 'user is not authorized' do
      before { user.update(authorized: false) }
      it do
        expect(CreatePeriodicReportUnauthorizedMessageWorker).to receive(:perform_async).with(user.id)
        subject
      end
    end

    context 'enough_permission_level? returns false' do
      before do
        allow(user).to receive(:enough_permission_level?).and_return(false)
      end
      it do
        expect(CreatePeriodicReportPermissionLevelNotEnoughMessageWorker).to receive(:perform_async).with(user.id)
        subject
      end
    end
  end
end
