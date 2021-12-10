require 'rails_helper'

describe DeleteTweetsByArchiveResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['アーカイブ削除 停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@stop)).to be_truthy
        end
      end
    end
  end

  describe '#stop_regexp' do
    subject { text.match?(instance.stop_regexp) }

    ['アーカイブ削除 停止', 'アーカイブ削除停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#change_regexp' do
    subject { text.match?(instance.change_regexp) }

    ['アーカイブ削除 更新', 'アーカイブ削除更新', 'アーカイブ削除 変更', 'アーカイブ削除変更'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#send_message' do
    subject { instance.send_message }
    before { instance.instance_variable_set(:@stop, true) }

    it do
      expect(CreateDeleteTweetsByArchiveStopRequestedMessageWorker).to receive(:perform_async).with(uid)
      subject
    end
  end
end
