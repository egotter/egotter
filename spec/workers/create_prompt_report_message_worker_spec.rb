require 'rails_helper'

RSpec.describe CreatePromptReportMessageWorker do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create!(user_id: user.id) }
  let(:worker) { CreatePromptReportMessageWorker.new }

  describe '#perform' do
    let(:record1) { create(:twitter_user) }
    let(:record2) { create(:twitter_user) }
    let(:options) do
      {
          'changes_json' => '{}',
          'previous_twitter_user_id' => record1.id,
          'current_twitter_user_id' => record2.id,
          'create_prompt_report_request_id' => request.id,
          'kind' => kind,
      }
    end
    let(:values) {
      {changes_json: options['changes_json'], previous_twitter_user: record1, current_twitter_user: record2, request_id: request.id}
    }
    subject { worker.perform(user.id, options) }

    context 'kind == :you_are_removed' do
      let(:kind) { :you_are_removed }

      before do
        allow(user).to receive(:active_access?).with(any_args).and_return(false)
      end
      it do
        expect(PromptReport).to receive(:you_are_removed).with(user.id, values).and_return(double('PromptReport', deliver!: nil))
        expect(WarningMessage).to receive(:inactive).with(user.id).and_return(double('WarningMessage', deliver!: nil))
        subject
      end
    end

    context 'kind == :not_changed' do
      let(:kind) { :not_changed }

      before do
        allow(user).to receive(:active_access?).with(any_args).and_return(false)
      end

      it do
        expect(PromptReport).to receive(:not_changed).with(user.id, values).and_return(double('PromptReport', deliver!: nil))
        expect(WarningMessage).to receive(:inactive).with(user.id).and_return(double('WarningMessage', deliver!: nil))
        subject
      end
    end

    context 'kind == :initialization' do
      let(:kind) { :initialization }

      it do
        expect(PromptReport).to receive(:initialization).with(user.id, request_id: request.id).and_return(double('PromptReport', deliver!: nil))
        subject
      end
    end

    context '#deriver! raises PromptReport::ReportingError' do
      let(:kind) { :you_are_removed }
      let(:exception) { PromptReport::ReportingError.new('Anything') }

      before do
        allow(PromptReport).to receive_message_chain(:you_are_removed, :deliver!).with(any_args).with(no_args).and_raise(exception)
      end

      it do
        expect(worker).to receive(:log).with(options).and_call_original
        subject
      end
    end

    context '#deriver! raises Twitter::Error::Forbidden' do
      let(:kind) { :you_are_removed }
      let(:exception) { Twitter::Error::Forbidden.new('You cannot send messages to users who are not following you.') }

      before do
        allow(PromptReport).to receive_message_chain(:you_are_removed, :deliver!).with(any_args).with(no_args).and_raise(exception)
      end

      it do
        expect(DirectMessageStatus).to receive(:cannot_send_messages?).with(exception).and_call_original
        expect(worker).to receive(:log).with(options).and_call_original
        subject
      end
    end
  end

  describe '#log' do
    subject { worker.log({'create_prompt_report_request_id' => 1}) }
    it { is_expected.to be_an_instance_of(CreatePromptReportLog) }
  end
end
