require 'rails_helper'

RSpec.describe CreateTwitterUserTask, type: :model do
  let(:user) { create(:user) }
  let(:request) { create(:create_twitter_user_request, user_id: user.id, uid: 1) }
  let(:task) { described_class.new(request) }

  describe '#start!' do
    let(:context) { 'context' }
    let(:twitter_user) { 'twitter_user' }
    subject { task.start!(context) }

    it do
      expect(request).to receive(:update).with(started_at: instance_of(ActiveSupport::TimeWithZone))
      expect(request).to receive(:perform!).with(context).and_return(twitter_user)
      expect(request).to receive(:update).with(finished_at: instance_of(ActiveSupport::TimeWithZone))
      subject
    end
  end
end
