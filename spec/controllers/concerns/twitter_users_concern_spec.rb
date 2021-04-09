require 'rails_helper'

describe TwitterUsersConcern, type: :controller do
  controller ApplicationController do
    include TwitterUsersConcern
  end

  let(:screen_name) { 'name' }
  let(:uid) { 100 }
  let(:user) { double('user') }
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
        expect(controller).to receive(:handle_twitter_api_error).with(error, :build_twitter_user_by)
        subject
      end
    end
  end

  describe '#build_twitter_user_by_uid' do
    subject { controller.build_twitter_user_by_uid(uid) }
    it do
      expect(client).to receive(:user).with(uid).and_return({screen_name: screen_name})
      expect(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name)
      subject
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before { allow(client).to receive(:user).with(anything).and_raise(error) }
      it do
        expect(controller).to receive(:handle_twitter_api_error).with(error, :build_twitter_user_by_uid)
        subject
      end
    end
  end

  describe '#handle_twitter_api_error' do
    let(:error) { RuntimeError.new }
    subject { controller.send(:handle_twitter_api_error, error, 'location') }

    context 'not_found' do
      before { allow(TwitterApiStatus).to receive(:not_found?).with(error).and_return(true) }
      it do
        expect(controller).to receive(:error_pages_twitter_error_not_found_path).with(anything).and_return('path')
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end

    context 'suspended' do
      before { allow(TwitterApiStatus).to receive(:suspended?).with(error).and_return(true) }
      it do
        expect(controller).to receive(:error_pages_twitter_error_suspended_path).with(anything).and_return('path')
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end

    context 'unauthorized' do
      before { allow(TwitterApiStatus).to receive(:unauthorized?).with(error).and_return(true) }
      it do
        expect(controller).to receive(:error_pages_twitter_error_unauthorized_path).with(anything).and_return('path')
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end

    context 'temporarily_locked' do
      before { allow(TwitterApiStatus).to receive(:temporarily_locked?).with(error).and_return(true) }
      it do
        expect(controller).to receive(:error_pages_twitter_error_temporarily_locked_path).with(anything).and_return('path')
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end

    context 'else' do
      it do
        expect(controller).to receive(:error_pages_twitter_error_unknown_path).with(anything).and_return('path')
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end
  end
end
