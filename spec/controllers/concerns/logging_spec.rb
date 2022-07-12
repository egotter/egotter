require 'rails_helper'

RSpec.describe Logging do
  controller ApplicationController do
    include Logging
  end

  describe '#create_access_day' do
    let(:user) { create(:user) }
    subject { controller.create_access_day }
    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end
    it do
      expect(CreateAccessDayWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#create_webhook_log' do
    let(:request) do
      double('request', query_parameters: {}, request_parameters: {}, path: '/', ip: '1.1.1.1', method: 'GET', user_agent: 'TEST')
    end
    let(:response) { double('response', status: 200) }
    subject { controller.create_webhook_log }
    before do
      allow(controller).to receive(:request).and_return(request)
      allow(controller).to receive(:response).and_return(response)
      allow(controller).to receive(:twitter_webhook?).and_return(true)
    end
    it do
      expect(CreateWebhookLogWorker).to receive(:perform_async).with(anything)
      subject
    end
  end
end
