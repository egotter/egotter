require 'rails_helper'

RSpec.describe Logging do
  controller ApplicationController do
    include Logging
  end

  let(:response) { double('response', status: 200) }

  before do
    allow(controller).to receive(:response).and_return(response)
  end

  describe '#create_access_log?' do
    subject { controller.create_access_log? }
    before { allow(response).to receive(:successful?).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#apache_bench?' do
    subject { controller.apache_bench? }
    it { is_expected.to be_falsey }
  end

  describe '#create_access_log' do
    subject { controller.create_access_log }
    it do
      expect(CreateSearchLogWorker).to receive(:perform_async).with(anything)
      subject
    end
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

  describe '#create_error_log' do
    subject { controller.create_error_log('location', 'message') }
    before { allow(controller).to receive(:performed?).and_return(false) }
    it do
      expect(CreateSearchErrorLogWorker).to receive(:perform_async).with(anything)
      subject
    end
  end

  describe '#create_crawler_log' do
    subject { controller.create_crawler_log }
    before { allow(controller).to receive(:performed?).and_return(false) }
    it do
      expect(CreateCrawlerLogWorker).to receive(:perform_async).with(anything)
      subject
    end
  end

  describe '#create_webhook_log' do
    subject { controller.create_webhook_log }
    before { allow(controller).to receive(:twitter_webhook?).and_return(true) }
    it do
      expect(CreateWebhookLogWorker).to receive(:perform_async).with(anything)
      subject
    end
  end

  describe '#create_stripe_webhook_log' do
    subject { controller.create_stripe_webhook_log('key', 'eid', 'etype', 'edata') }
    it do
      hash = {
          controller: instance_of(String),
          action: nil,
          path: instance_of(String),
          idempotency_key: 'key',
          event_id: 'eid',
          event_type: 'etype',
          event_data: 'edata',
          ip: instance_of(String),
          method: instance_of(String),
          status: instance_of(Integer),
          user_agent: instance_of(String),
      }
      expect(CreateStripeWebhookLogWorker).to receive(:perform_async).with(hash)
      subject
    end
  end

  describe '#ensure_utf8' do
    let(:str) { "あ".force_encoding('ASCII-8BIT') }
    subject { controller.send(:ensure_utf8, str) }
    it { expect(subject.encoding.name).to eq('UTF-8') }
  end
end
