require 'rails_helper'

RSpec.describe SendReceivedMessageWorker do
  let(:worker) { described_class.new }

  describe '#static_message?' do
    subject { worker.static_message?(I18n.t('quick_replies.continue.label')) }
    it { is_expected.to be_truthy }
  end
end
