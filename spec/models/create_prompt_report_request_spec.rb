require 'rails_helper'

RSpec.describe CreatePromptReportRequest, type: :model do
  describe '#too_many_errors?' do
    let(:user) { create(:user) }
    subject { CreatePromptReportRequest.new(user_id: user.id) }

    it { expect(subject.too_many_errors?).to be_falsey }

    context 'There are 2 error logs' do
      before do
        2.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it { expect(subject.too_many_errors?).to be_falsey }
    end

    context 'There are more than 3 error logs' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: 'Error') }
      end
      it { expect(subject.too_many_errors?).to be_truthy }
    end

    context 'There are more than 3 error logs, but error_class is empty' do
      before do
        3.times { CreatePromptReportLog.create!(user_id: user.id, error_class: '', error_message: "I'm an error") }
      end
      it { expect(subject.too_many_errors?).to be_falsey }
    end
  end
end
