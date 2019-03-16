require 'rails_helper'

RSpec.describe Egotter::Sidekiq::ExpireJob do
  let(:middleware_class) do
    Class.new(Egotter::Sidekiq::ExpireJob) do
    end
  end

  let(:middleware) do
    middleware_class.new
  end

  let(:worker_class) do
    Class.new do
      def expire_in
        1.minute
      end

      def after_expire(*args)
        'hello'
      end

      def logger
        Logger.new('/dev/null')
      end
    end
  end

  let(:worker) do
    worker_class.new
  end

  let(:enqueued_at) { Time.zone.now.to_s }

  let(:msg) do
    {'args' => [1, {'enqueued_at' => enqueued_at}]}
  end

  subject do
    middleware.call(worker, msg, nil) {'block result'}
  end

  it 'yields' do
    is_expected.to eq('block result')
  end

  context "Worker doesn't respond to #expire_in" do
    before { worker_class.class_eval { remove_method :expire_in } }
    it 'yields' do
      is_expected.to eq('block result')
    end
  end

  context 'With expired job' do
    let(:enqueued_at) { 1.hour.ago.to_s }
    it 'returns false' do
      is_expected.to be_falsey
    end

    it 'calls callback' do
      expect(worker).to receive(:after_expire).with(*msg['args'])
      subject
    end
  end
end
