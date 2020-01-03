require 'rails_helper'

RSpec.describe CreateTestReportRequest, type: :model do
  let(:user) { create(:user, with_settings: true) }
  let(:request) { described_class.create!(user_id: user.id) }

  describe '#perform!' do
    subject { request.perform! }
    it do
      expect(request).to receive(:error_check!)
      expect(CreatePromptReportLog).to receive(:reset_too_many_errors).with(user, 'TestReport was sent')
      subject
    end
  end

  describe '#error_check!' do
    let(:create_prompt_report_request) { CreatePromptReportRequest.new(user_id: user.id) }
    subject { request.error_check! }

    before { allow(CreatePromptReportRequest).to receive(:new).with(user_id: user.id).and_return(create_prompt_report_request) }

    it do
      expect(request).to receive(:communication_test!)
      expect(create_prompt_report_request).to receive(:error_check!)
      subject
    end

    context 'An exception is raised' do
      before { allow(request).to receive(:communication_test!).and_raise('Anything') }
      it do
        subject
        expect(request.error).to match(name: RuntimeError.to_s, message: 'Anything')
      end
    end
  end

  describe '#communication_test!' do
    let(:user_client) { DirectMessageClient.new(nil) }
    let(:egotter_client) { DirectMessageClient.new(nil) }
  end
end
