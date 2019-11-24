require 'rails_helper'

RSpec.describe PromptReport, type: :model do
  let(:user) { create(:user) }
  let(:prompt_report) { PromptReport.new(user_id: user.id, changes_json: {followers_count: [100, 99]}, token: PromptReport.token) }

  describe '.generate_token' do
    it 'generates a unique token' do
      expect(PromptReport.generate_token).to be_truthy
    end
  end

  describe '#deliver!' do
    let(:dm_client_class) do
      Class.new do
        def create_direct_message(uid, message)
          @count ||= 0
          if @count == 0
            @count += 1
            {event: {id: 'id1', message_create: {message_data: {text: 'text1'}}}}
          else
            {event: {id: 'id2', message_create: {message_data: {text: 'text2'}}}}
          end
        end
      end
    end

    let(:user) { create(:user) }
    subject { build(:prompt_report, user: user) }

    before do
      user.create_notification_setting!
      allow(subject).to receive(:dm_client).with(anything).and_return(dm_client_class.new)
    end

    it 'calls #send_starting_message! and #send_reporting_message!' do
      is_expected.to receive(:send_starting_message!).with(no_args).and_call_original
      is_expected.to receive(:send_reporting_message!).with(no_args).and_call_original
      is_expected.to receive(:update_with_dm!).with(anything).twice.and_call_original
      subject.deliver!

      expect(subject.message_id).to eq('id2')
      expect(subject.message).to eq('text2')
    end

    context 'send_reporting_message! raises an exception' do
      before do
        allow(subject).to receive(:send_reporting_message!).and_raise
      end

      it 'calls #send_starting_message! and #send_failed_message!' do
        is_expected.to receive(:send_starting_message!).with(no_args).and_call_original
        is_expected.to receive(:send_failed_message!).with(no_args).and_call_original
        is_expected.to receive(:update_with_dm!).with(anything).twice.and_call_original
        subject.deliver!

        expect(subject.message_id).to eq('id2')
        expect(subject.message).to eq('text2')
      end
    end
  end
end
