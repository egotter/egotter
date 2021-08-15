require 'rails_helper'

describe MemoMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [' https://twitter.com/messages/media/111'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@memo)).to be_truthy
        end
      end
    end
  end

  describe '#received_regexp' do
    subject { text.match?(instance.received_regexp) }

    [' https://twitter.com/messages/media/111'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    [
        'Hello https://twitter.com/messages/media/111',
        'https://twitter.com/messages/media/111',
        'https://twitter.com/messages/media/111 '
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    let(:user) { create(:user, uid: uid) }
    subject { instance.send_message }
    before do
      instance.instance_variable_set(:@memo, true)
      instance.instance_variable_set(:@uid, 1)
    end

    it do
      expect(CreateMemoMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
