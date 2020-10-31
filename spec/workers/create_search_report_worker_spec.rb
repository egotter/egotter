require 'rails_helper'

RSpec.describe CreateSearchReportWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user, with_settings: true) }
    subject { worker.perform(user.id) }
    it do
      expect(SearchReport).to receive_message_chain(:you_are_searched, :deliver!).
          with(user.id, anything).with(no_args)
      subject
    end
  end
end