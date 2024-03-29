require 'rails_helper'

RSpec.describe JobQueueingConcern, type: :controller do
  controller ApplicationController do
    include JobQueueingConcern
  end

  let(:user) { create(:user) }

  before do
    RedisClient.new.flushall
    allow(controller).to receive(:user_signed_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  after do
    RedisClient.new.flushall
  end

  describe '#request_creating_twitter_user' do
    subject { controller.request_creating_twitter_user(user.uid) }
    it do
      expect(CreateTwitterUserWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end

  describe '#request_assembling_twitter_user' do
    let(:twitter_user) { create(:twitter_user, created_at: 1.minute.ago) }
    subject { controller.request_assembling_twitter_user(twitter_user) }
    it do
      expect(AssembleTwitterUserWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end
end
