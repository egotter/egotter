require 'rails_helper'

RSpec.describe TestMessage do
end

RSpec.describe TestMessage::NeedFixMessageBuilder do
  let(:older) { TwitterUser.new }
  let(:newer) { TwitterUser.new }

  describe '#readable_error_class' do
    let(:error) { 'CreatePromptReportRequest::TooShortRequestInterval' }

    it 'returns translated value' do
      expect(described_class.new(nil, nil, nil, nil).readable_error_class(error)).to eq(I18n.t('dm.testMessage.errors.TooShortRequestInterval'))
    end

    context 'invalid error value' do
      let(:error) { 'Anything' }
      it 'returns default value' do
        expect(described_class.new(nil, nil, nil, nil).readable_error_class(error)).to eq(error)
      end
    end
  end

  describe '#readable_error_message' do
    let(:error) { 'CreatePromptReportRequest::TooShortRequestInterval' }
    let(:message) { 'This is a message.' }

    it 'returns translated value' do
      expect(described_class.new(nil, nil, nil, nil).readable_error_message(error, message)).to eq(I18n.t('dm.testMessage.messages.TooShortRequestInterval'))
    end

    context 'invalid error value' do
      let(:error) { 'Anything' }
      it 'returns default value' do
        expect(described_class.new(nil, nil, nil, nil).readable_error_message(error, message)).to eq(message)
      end
    end
  end
end
