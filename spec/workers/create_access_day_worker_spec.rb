require 'rails_helper'

RSpec.describe CreateAccessDayWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(user.id) }
    it { expect { subject }.to change { AccessDay.all.size }.by(1) }
  end
end
