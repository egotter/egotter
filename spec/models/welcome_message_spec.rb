require 'rails_helper'

RSpec.describe WelcomeMessage, type: :model do
  describe '#deliver!' do
    let(:dm_client_class) do
      Class.new do
        def create_direct_message(uid, message)
          @count ||= 0
          @count += 1
          {event: {id: "id#{@count}", message_create: {message_data: {text: "text#{@count}"}}}}
        end
      end
    end

    let(:user) { create(:user) }
    subject { build(:welcome_message, user: user) }

    before do
      user.create_notification_setting!
      allow(subject).to receive(:dm_client).with(anything).and_return(dm_client_class.new)
    end

    it 'calls #send_first_of_all_message!, #send_test_message_from_egotter! and #send_initialization_success_message!' do
      is_expected.to receive(:send_first_of_all_message!).with(no_args).and_call_original
      is_expected.to receive(:send_test_message_from_egotter!).with(no_args).and_call_original
      is_expected.to receive(:send_initialization_success_message!).with(no_args).and_call_original
      is_expected.not_to receive(:send_initialization_failed_message!)
      is_expected.to receive(:update!).with(anything).thrice.and_call_original
      subject.deliver!

      expect(subject.message_id).to eq('id3')
      expect(subject.message).to eq('text3')
    end

    context '#send_test_message_from_egotter! raises an exception' do
      before do
        allow(subject).to receive(:send_test_message_from_egotter!).and_raise
      end

      it 'calls #send_first_of_all_message! and #send_initialization_failed_message!' do
        is_expected.to receive(:send_first_of_all_message!).with(no_args).and_call_original
        is_expected.to receive(:send_initialization_failed_message!).with(no_args).and_call_original
        is_expected.not_to receive(:send_initialization_success_message!)
        is_expected.to receive(:update!).with(anything).twice.and_call_original
        expect { subject.deliver! }.to raise_error(WelcomeMessage::ReportingFailed)


        expect(subject.message_id).to eq('id2')
        expect(subject.message).to eq('text2')
      end
    end
  end
end
