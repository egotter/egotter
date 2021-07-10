require 'rails_helper'

describe DeleteTweetsMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    [
        'ツイート削除 開始'
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@vague)).to be_truthy
        end
      end
    end

    [
        'ツイート削除 開始 abc123'
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@start)).to be_truthy
        end
      end
    end

    [
        'ツイ消し',
        'つい消し',
        '削除',
        'クリーナー',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@inquiry)).to be_truthy
        end
      end
    end
  end

  describe '#start_regexp' do
    it do
      expect(instance.start_regexp.match('ツイート削除 開始 abc123')[:token]).to eq('abc123')
    end
  end

  describe '#send_message' do
    subject { instance.send_message }

    context '@inquiry is set' do
      before { instance.instance_variable_set(:@inquiry, true) }
      it do
        expect(CreateDeleteTweetsQuestionedMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@vague is set' do
      before { instance.instance_variable_set(:@vague, true) }
      it do
        expect(CreateDeleteTweetsInvalidRequestMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@start is set' do
      let(:text) { 'ツイート削除 開始 abc123' }
      let(:user) { create(:user, uid: uid) }
      let(:request) { create(:delete_tweets_request, user_id: user.id) }
      before do
        instance.instance_variable_set(:@start, true)
        allow(instance).to receive(:validate_report_status).with(uid).and_return(user)
        allow(DeleteTweetsRequest).to receive_message_chain(:where, :find_by_token).
            with(user_id: user.id).with('abc123').and_return(request)
      end
      it do
        expect(DeleteTweetsWorker).to receive(:perform_in).with(10.seconds, request.id)
        expect(CreateDeleteTweetsRequestStartedMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end
  end
end
