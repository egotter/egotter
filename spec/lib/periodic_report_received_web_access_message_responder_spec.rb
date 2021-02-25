require 'rails_helper'

describe PeriodicReportReceivedWebAccessMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['アクセス通知届きました', 'アクセス通知 届きました', 'URLにアクセスしました'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end
end
