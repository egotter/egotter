require 'rails_helper'

describe TwitterUsersConcern, type: :controller do
  controller ApplicationController do
    include TwitterUsersConcern
  end

  let(:screen_name) { 'name' }
  let(:user) { 'user' }
  let(:client) { double('client') }

  before do
    allow(controller).to receive(:request_context_client).and_return(client)
  end

  describe '#build_twitter_user_by' do
    subject { controller.build_twitter_user_by(screen_name: screen_name) }
    it do
      expect(client).to receive(:user).with(screen_name).and_return(user)
      expect(TwitterUser).to receive(:build_by).with(user: user)
      subject
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(client).to receive(:user).with(anything).and_raise(error) }
      it do
        expect(controller).to receive(:handle_twitter_api_error).with(error, screen_name)
        subject
      end
    end
  end

  describe '#handle_twitter_api_error' do
    let(:error) { RuntimeError.new }
    subject { controller.handle_twitter_api_error(error, screen_name) }
    it do
      expect(TwitterApiStatus).to receive(:not_found?).with(error)
      expect(TwitterApiStatus).to receive(:suspended?).with(error)
      expect(TwitterApiStatus).to receive(:invalid_or_expired_token?).with(error)
      expect(TwitterApiStatus).to receive(:temporarily_locked?).with(error)
      expect(controller).to receive(:twitter_exception_messages).with(error, screen_name).and_return('message')
      expect(controller).to receive(:respond_with_error).with(:bad_request, 'message')
      subject
    end
  end
end
