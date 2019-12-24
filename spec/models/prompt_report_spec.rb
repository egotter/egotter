require 'rails_helper'

RSpec.describe PromptReport, type: :model do

  describe '.generate_token' do
    it 'generates a unique token' do
      expect(PromptReport.generate_token).to be_truthy
    end
  end

  describe '.initialization' do
    let(:user) { create(:user) }
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
    let(:user) { create(:user) }
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
    let(:user) { create(:user) }
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
    let(:dm_client_class) do
      Class.new do
        def create_direct_message(*args)
          @count ||= 0
          @count += 1
          {event: {id: "id#{@count}", message_create: {message_data: {text: "text#{@count}"}}}}
        end
      end
    end

    let(:user) { create(:user) }
    let(:prompt_report) { build(:prompt_report, user: user) }
    subject { prompt_report.deliver! }

    before do
      user.create_notification_setting!
      allow(prompt_report).to receive(:dm_client).with(anything).and_return(dm_client_class.new)
      prompt_report.message_builder = described_class::EmptyMessageBuilder.new
    end

    it 'calls #send_starting_message! and #send_reporting_message!' do
      expect(prompt_report).to receive(:send_starting_message!).with(no_args).and_call_original
      expect(prompt_report).to receive(:send_reporting_message!).with(no_args).and_call_original
      expect(prompt_report).to receive(:update_with_dm!).with(anything).twice.and_call_original
      subject

      expect(prompt_report.persisted?).to be_truthy
      expect(prompt_report.message_id).to eq('id2')
      expect(prompt_report.message).to eq('text2')
    end

    context '#send_reporting_message! raises an exception' do
      before { allow(prompt_report).to receive(:send_reporting_message!).and_raise('Anything') }

      it 'calls #send_starting_message! and #send_failed_message!' do
        expect(prompt_report).to receive(:send_starting_message!).with(no_args).and_call_original
        expect(prompt_report).to receive(:send_failed_message!).with(no_args).and_call_original
        expect(prompt_report).to receive(:update_with_dm!).with(anything).twice.and_call_original
        expect { subject }.to raise_error(PromptReport::ReportingFailed)

        expect(prompt_report.persisted?).to be_truthy
        expect(prompt_report.message_id).to eq('id2')
        expect(prompt_report.message).to eq('text2')
      end
    end

    context 'prompt_record is persisted' do
      before { prompt_report.save! }
      it do
        expect(prompt_report).not_to receive(:send_starting_message!)
        subject
      end
    end
  end

  describe '#deliver_starting_message!' do
    let(:user) { create(:user) }
    let(:prompt_report) { build(:prompt_report, user: user) }
    let(:response) { {event: {id: 'id', message_create: {message_data: {text: 'text'}}}} }
    subject { prompt_report.deliver_starting_message! }

    before do
      user.create_notification_setting!
      allow(prompt_report).to receive(:send_starting_message!).and_return(response)
    end

    it do
      expect(DirectMessage).to receive(:new).with(response).and_call_original
      expect(prompt_report).to receive(:update_with_dm!).with(instance_of(DirectMessage))
      subject
    end
  end

  describe '#update_with_dm!' do
    let(:user) { create(:user) }
    let(:prompt_report) { build(:prompt_report, user: user) }
    let(:dm) { double('dm', id: 'id', truncated_message: 'message') }
    subject { prompt_report.send(:update_with_dm!, dm) }

    before { user.create_notification_setting! }

    context 'prompt_report is new record' do
      it { expect { subject }.to change { PromptReport.all.size }.by(1) }
    end

    context 'prompt_report is persisted' do
      before { prompt_report.save! }
      it { expect { subject }.not_to change { PromptReport.all.size } }
    end
  end
end
