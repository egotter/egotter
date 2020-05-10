require 'rails_helper'

RSpec.describe CreatePromptReportMessageWorker do
  let(:user) { create(:user) }
  let(:request) { CreatePromptReportRequest.create!(user_id: user.id) }
  let(:prompt_report) { create(:prompt_report, user_id: user.id) }
  let(:worker) { CreatePromptReportMessageWorker.new }

  describe '#perform' do
    let(:kind) { :kind }
    let(:options) { {'kind' => kind} }
    subject { worker.perform(user.id, options) }
    before { allow(User).to receive(:find).with(user.id).and_return(user) }
    it do
      expect(worker).to receive(:send_report).with(kind, user, options)
      # expect(worker).to receive(:send_warning_message).with(kind, user, options)
      subject
    end

    context '#send_report raises PromptReport::ReportingError' do
      let(:exception) { PromptReport::ReportingError.new('Anything') }
      let(:log) { CreatePromptReportLog.new }
      before { allow(worker).to receive(:send_report).with(any_args).and_raise(exception) }
      it do
        expect(worker).to receive(:log).with(options).and_return(log)
        subject
      end
    end

    context '#send_report raises Twitter::Error::Forbidden' do
      let(:exception) { Twitter::Error::Forbidden.new('You cannot send messages to users who are not following you.') }
      let(:log) { CreatePromptReportLog.new }
      before { allow(worker).to receive(:send_report).with(any_args).and_raise(exception) }
      it do
        expect(worker).to receive(:not_fatal_error?).with(exception).and_call_original
        expect(worker).to receive(:log).with(options).and_return(log)
        subject
      end
    end
  end

  describe '#send_report' do
    let(:options) { 'options' }
    let(:report_args) do
      [
          user.id,
          changes_json: nil,
          previous_twitter_user: nil,
          current_twitter_user: nil,
          request_id: request.id,
          id: prompt_report.id,
      ]
    end
    let(:report) { double('PromptReport', deliver!: nil) }
    subject { worker.send_report(kind, user, options) }

    before do
      allow(worker).to receive(:report_args).with(user, options).and_return(report_args)
      allow(user).to receive(:active_access?).with(CreatePromptReportRequest::ACTIVE_DAYS_WARNING).and_return(true)
      allow(user).to receive(:following_egotter?).and_return(true)
    end

    context 'kind == :you_are_removed' do
      let(:kind) { :you_are_removed }
      it do
        expect(PromptReport).to receive(:you_are_removed).with(*report_args).and_return(report)
        subject
      end
    end

    context 'kind == :not_changed' do
      let(:kind) { :not_changed }
      it do
        expect(PromptReport).to receive(:not_changed).with(*report_args).and_return(report)
        subject
      end
    end

    context 'kind == :initialization' do
      let(:kind) { :initialization }
      let(:options) { {'create_prompt_report_request_id' => request.id, 'prompt_report_id' => prompt_report.id} }
      it do
        expect(PromptReport).to receive(:initialization).with(user.id, request_id: request.id, id: prompt_report.id).and_return(report)
        subject
      end
    end
  end

  describe '#send_warning_message' do
    let(:options) { 'options' }
    subject { worker.send_warning_message(kind, user, options) }

    context 'kind == :you_are_removed' do
      let(:kind) { :you_are_removed }
      it do
        expect(user).to receive(:active_access?).with(CreatePromptReportRequest::ACTIVE_DAYS_WARNING).and_return(false)
        expect(WarningMessage).to receive(:inactive_message).with(user.id).and_return(double('WarningMessage', deliver!: nil))
        subject
      end
    end

    context 'kind == :not_changed' do
      let(:kind) { :not_changed }
      it do
        expect(user).to receive(:active_access?).with(CreatePromptReportRequest::ACTIVE_DAYS_WARNING).and_return(false)
        expect(WarningMessage).to receive(:inactive_message).with(user.id).and_return(double('WarningMessage', deliver!: nil))
        subject
      end
    end

    context 'kind == :initialization' do
      let(:kind) { :initialization }
      let(:log) { CreatePromptReportLog.new }
      it do
        expect(worker).to receive(:log).with(options).and_return(log)
        subject
      end
    end
  end

  describe '#report_args' do
    let(:record1) { create(:twitter_user) }
    let(:record2) { create(:twitter_user) }
    let(:options) do
      {
          'changes_json' => '{}',
          'previous_twitter_user_id' => record1.id,
          'current_twitter_user_id' => record2.id,
          'create_prompt_report_request_id' => request.id,
          'prompt_report_id' => prompt_report.id,
      }
    end
    subject { worker.report_args(user, options) }

    before do
      allow(TwitterUser).to receive(:find).with(record1.id).and_return(record1)
      allow(TwitterUser).to receive(:find).with(record2.id).and_return(record2)
    end
    it do
      is_expected.to match([user.id, {
          changes_json: '{}',
          previous_twitter_user: record1,
          current_twitter_user: record2,
          request_id: request.id,
          id: prompt_report.id,
      }])
    end
  end

  describe '#log' do
    subject { worker.log({'create_prompt_report_request_id' => 1}) }
    it { is_expected.to be_an_instance_of(CreatePromptReportLog) }
  end
end
