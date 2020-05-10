require 'rails_helper'

RSpec.describe CreatePeriodicReportMessageWorker do
  let(:user) { create(:user) }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:options) { {} }
    subject { worker.perform(user.id, options) }

    %i(
      you_have_blocked?
      not_following_you?
      cannot_find_specified_user?
      protect_out_users_from_spam?
    ).each do |method|
      context "#{method} returns true" do
        before do
          allow(options).to receive(:symbolize_keys!).and_raise('anything')
          allow(DirectMessageStatus).to receive(method).with(anything).and_return(true)
        end
        it do
          expect(worker.logger).to receive(:info).with(instance_of(String))
          subject
        end
      end

      context "unknown exception is raised" do
        before do
          allow(options).to receive(:symbolize_keys!).and_raise('unknown')
        end
        it do
          expect(worker.logger).to receive(:warn).with(instance_of(String))
          subject
        end
      end
    end
  end
end
