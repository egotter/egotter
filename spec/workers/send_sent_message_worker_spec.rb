require 'rails_helper'

RSpec.describe SendSentMessageWorker do
  let(:worker) { described_class.new }

  describe '#static_message?' do
    subject { worker.static_message?(I18n.t('quick_replies.prompt_reports.label3')) }
    it { is_expected.to be_truthy }
  end
end
