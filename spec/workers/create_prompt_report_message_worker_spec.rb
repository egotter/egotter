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

    context 'kind == :you_are_removed' do
      let(:kind) { :you_are_removed }
      subject { worker.perform(user.id, options) }

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
      subject { worker.perform(user.id, options) }

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
      subject { worker.perform(user.id, options) }

      it do
        expect(PromptReport).to receive(:initialization).with(user.id, request_id: request.id).and_return(double('PromptReport', deliver!: nil))
        subject
      end
    end
  end
end
