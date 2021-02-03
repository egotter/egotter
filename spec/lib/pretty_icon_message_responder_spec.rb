require 'rails_helper'

describe PrettyIconMessageResponder do
  let(:dm) { double('dm', sender_id: 1, text: 'text') }
  let(:instance) { described_class.new(dm) }

  describe '#respond' do
    subject { instance.respond }
    it { is_expected.to be_falsey }
  end
end

describe PrettyIconMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['アイコン可愛い', 'アイコン可愛くなった？'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['おつかれんこん'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    it do
      expect(CreatePrettyIconMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
