require 'rails_helper'

RSpec.describe PromptReport, type: :model do
  let(:user) { create(:user, with_settings: true) }

  describe '.generate_token' do
    it 'generates a unique token' do
      expect(PromptReport.generate_token).to be_truthy
    end
  end

  describe '.initialization' do
    let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
    subject { described_class.initialization(user.id, request_id: request.id, id: prompt_report.id) }

    context 'id is nil' do
      let(:prompt_report) { build(:prompt_report, user_id: user.id) }
      it { expect(subject.new_record?).to be_truthy }
    end

    context 'id is an id of persisted record' do
      let(:prompt_report) { create(:prompt_report, user_id: user.id) }
      it { expect(subject.persisted?).to be_truthy }
    end
  end

  describe '.you_are_removed' do
    let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
    subject do
      described_class.you_are_removed(
          user.id,
          changes_json: '{}',
          previous_twitter_user: nil,
          current_twitter_user: nil,
          request_id: request.id,
          id: prompt_report.id)
    end

    before do
      # TODO Low quality
      allow(described_class::YouAreRemovedMessageBuilder).to receive(:new).with(any_args).and_return(spy('MessageBuilder'))
    end

    context 'id is nil' do
      let(:prompt_report) { build(:prompt_report, user_id: user.id) }
      it { expect(subject.new_record?).to be_truthy }
    end

    context 'id is an id of persisted record' do
      let(:prompt_report) { create(:prompt_report, user_id: user.id) }
      it { expect(subject.persisted?).to be_truthy }
    end
  end

  describe '.not_changed' do
    let(:request) { CreatePromptReportRequest.create(user_id: user.id) }
    subject do
      described_class.not_changed(
          user.id,
          changes_json: '{}',
          previous_twitter_user: nil,
          current_twitter_user: nil,
          request_id: request.id,
          id: prompt_report.id)
    end

    before do
      # TODO Low quality
      allow(described_class::NotChangedMessageBuilder).to receive(:new).with(any_args).and_return(spy('MessageBuilder'))
    end

    context 'id is nil' do
      let(:prompt_report) { build(:prompt_report, user_id: user.id) }
      it { expect(subject.new_record?).to be_truthy }
    end

    context 'id is an id of persisted record' do
      let(:prompt_report) { create(:prompt_report, user_id: user.id) }
      it { expect(subject.persisted?).to be_truthy }
    end
  end

  describe '#deliver!' do
    let(:prompt_report) { build(:prompt_report, user: user) }
    subject { prompt_report.deliver! }

    before { prompt_report.message_builder = described_class::EmptyMessageBuilder.new }

    it do
      expect(prompt_report).to receive(:deliver_starting_message!)
      expect(prompt_report).to receive(:deliver_reporting_message!).and_return('dm')
      is_expected.to eq('dm')
    end
  end

  describe '#deliver_starting_message!' do
    let(:report) { build(:prompt_report, user: user) }
    subject { report.deliver_starting_message! }

    it do
      expect(report).to receive(:send_starting_message!).and_return('dm')
      expect(report).to receive(:update_with_dm!).with('dm')
      is_expected.to eq('dm')
    end

    context 'An exception is raised' do
      before { allow(report).to receive(:send_starting_message!).and_raise('Anything') }
      it { expect { subject }.to raise_error(described_class::StartingFailed, 'RuntimeError Anything') }
    end
  end

  describe '#deliver_reporting_message!' do
    let(:report) { build(:prompt_report, user: user) }
    subject { report.deliver_reporting_message! }

    it do
      expect(report).to receive(:send_reporting_message!).and_return('dm')
      expect(report).to receive(:update_with_dm!).with('dm')
      is_expected.to eq('dm')
    end

    context 'An exception is raised' do
      before { allow(report).to receive(:send_reporting_message!).and_raise('Anything') }
      it { expect { subject }.to raise_error(described_class::ReportingFailed, 'RuntimeError Anything') }
    end
  end

  describe '#deliver_stopped_message!' do
    let(:report) { build(:prompt_report, user: user) }
    subject { report.deliver_stopped_message! }

    it do
      expect(report).to receive(:send_stopped_message!).and_return('dm')
      expect(report).to receive(:update_with_dm!).with('dm')
      is_expected.to eq('dm')
    end

    context 'An exception is raised' do
      before { allow(report).to receive(:send_stopped_message!).and_raise('Anything') }
      it { expect { subject }.to raise_error(described_class::StartingFailed, 'RuntimeError Anything') }
    end
  end

  describe '#send_starting_message!' do
    let(:report) { build(:prompt_report, user: user) }
    let(:api_client) { instance_double('ApiClient') }
    subject { report.send(:send_starting_message!) }

    before { allow(user).to receive(:api_client).and_return(api_client) }

    it do
      expect(api_client).to receive(:create_direct_message_event).with(User::EGOTTER_UID, anything).and_return('dm')
      is_expected.to eq('dm')
    end
  end

  describe '#send_stopped_message!' do
    let(:report) { build(:prompt_report, user: user) }
    let(:api_client) { instance_double('ApiClient') }
    subject { report.send(:send_stopped_message!) }

    before { allow(user).to receive(:api_client).and_return(api_client) }

    it do
      expect(api_client).to receive(:create_direct_message_event).with(User::EGOTTER_UID, anything).and_return('dm')
      is_expected.to eq('dm')
    end
  end

  describe '#send_reporting_message!' do
    let(:report) { build(:prompt_report, user: user) }
    let(:api_client) { instance_double('ApiClient') }
    subject { report.send(:send_reporting_message!) }

    before do
      allow(User).to receive_message_chain(:egotter, :api_client).and_return(api_client)
      allow(report).to receive(:message_builder).and_return(described_class::EmptyMessageBuilder.new)
    end

    it do
      expect(api_client).to receive(:create_direct_message_event).with(user.uid, anything).and_return('dm')
      is_expected.to eq('dm')
    end
  end

  describe '#update_with_dm!' do
    let(:prompt_report) { build(:prompt_report, user: user) }
    let(:dm) { double('dm', id: 'id', truncated_message: 'message') }
    subject { prompt_report.send(:update_with_dm!, dm) }

    context 'prompt_report is new record' do
      it { expect { subject }.to change { PromptReport.all.size }.by(1) }
    end

    context 'prompt_report is persisted' do
      before { prompt_report.save! }
      it { expect { subject }.not_to change { PromptReport.all.size } }
    end
  end
end
