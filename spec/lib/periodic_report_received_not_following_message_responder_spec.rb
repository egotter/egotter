require 'rails_helper'

describe PeriodicReportReceivedNotFollowingMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['フォロー通知届きました', 'フォロー通知 届きました', 'フォローしました', 'フォロー しました'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end
end
