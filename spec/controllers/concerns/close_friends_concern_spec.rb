require 'rails_helper'

describe CloseFriendsConcern do
  let(:instance) { Object.new }

  before do
    instance.extend CloseFriendsConcern
  end

  describe '#process_close_friends' do
    let(:dm) { double('dm', sender_id: 1, text: 'text') }
    subject { instance.process_close_friends(dm) }

    it { is_expected.to be_falsey }

    context '#received? returns true' do
      before { allow(instance).to receive(:close_friends_questioned?).and_return(true) }
      it do
        expect(instance).to receive(:answer_close_friends_question).with(dm.sender_id)
        is_expected.to be_truthy
      end
    end
  end

  describe '#close_friends_questioned?' do
    subject { instance.close_friends_questioned?(text) }

    ['仲良しランキング', '仲良し', 'ランキング'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end
end
