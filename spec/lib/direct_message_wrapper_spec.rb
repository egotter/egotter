require 'rails_helper'

RSpec.describe DirectMessageWrapper, type: :model do
  describe '.from_event' do
    let(:event) do
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: 1},
              message_data: {
                  text: 'text'
              }
          }
      }
    end
    subject { described_class.from_event(event) }
    it do
      dm = subject
      expect(dm.recipient_id).to eq(1)
      expect(dm.text).to eq('text')
    end
  end

  describe '.from_json' do
    subject { described_class.from_json(json) }
    let(:json) do
      {
          event: {
              type: 'message_create',
              message_create: {
                  target: {recipient_id: 1},
                  message_data: {
                      text: 'text'
                  }
              }
          }
      }.to_json
    end
    subject { described_class.from_json(json) }
    it do
      dm = subject
      expect(dm.recipient_id).to eq(1)
      expect(dm.text).to eq('text')
    end
  end

  describe '.from_args' do
    subject { described_class.from_args(args) }

    context 'Pass uid and message' do
      let(:args) { [1, 'text'] }
      it do
        dm = subject
        expect(dm.recipient_id).to eq(1)
        expect(dm.text).to eq('text')
      end
    end

    context 'Pass event' do
      let(:event) do
        {
            type: 'message_create',
            message_create: {
                target: {recipient_id: 1},
                message_data: {
                    text: 'text'
                }
            }
        }
      end
      let(:args) { [event: event] }
      it do
        dm = subject
        expect(dm.recipient_id).to eq(1)
        expect(dm.text).to eq('text')
      end
    end
  end
end
