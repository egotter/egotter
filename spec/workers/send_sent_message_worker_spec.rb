require 'rails_helper'

RSpec.describe SendSentMessageWorker do
  let(:worker) { described_class.new }

  describe '#static_message?' do
    [
        I18n.t('quick_replies.prompt_reports.label3'),
        'aaa #egotter',
        "よし！\n#{Kaomoji::KAWAII.sample}",
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end
end
