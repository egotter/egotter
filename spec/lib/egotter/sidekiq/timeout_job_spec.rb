require 'rails_helper'

RSpec.describe Egotter::Sidekiq::TimeoutJob do
  let(:middleware) { described_class.new }

  describe '#call' do
    let(:worker) { double('Worker') }
    let(:msg) { {'args' => [1]} }
    let(:timeout_in) { 1.minute }
    let(:block) { Proc.new {} }

    context 'The worker implements #timeout_in' do
      before { allow(worker).to receive(:timeout_in).and_return(timeout_in) }

      it do
        expect(middleware).to receive(:yield_with_timeout).with(worker, msg['args'], timeout_in) { |&blk| expect(blk).to be(block) }
        middleware.call(worker, msg, nil, &block)
      end
    end

    context "The worker doesn't implement #timeout_in" do
      before { allow(worker).to receive(:respond_to?).with(:timeout_in).and_return(false) }
      it do
        expect(middleware).not_to receive(:yield_with_timeout)
        expect { |b| middleware.call(worker, msg, nil, &b) }.to yield_control
      end
    end
  end

  describe '#yield_with_timeout' do
    let(:worker) { double('Worker') }
    let(:args) { [1] }
    let(:timeout_in) { 0.1 }
    subject { middleware.yield_with_timeout(worker, args, timeout_in, &block) }

    before { allow(worker).to receive(:logger).and_return(Logger.new(nil)) }

    context 'Finish everything in time' do
      let(:block) { Proc.new { true } }
      it { is_expected.to be_truthy }
    end

    context 'Time is up' do
      let(:block) { Proc.new { sleep 1; true } }
      it do
        expect(worker).to receive(:after_timeout).with(*args)
        is_expected.to be_nil
      end
    end
  end

  context 'Server side job running' do
    class TestTimeoutWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@count = 0
      @@callback_count = 0

      def timeout_in
        0.1
      end

      def after_timeout(*args)
        @@callback_count += 1
      end

      def perform(*args)
        sleep 1
        @@count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Egotter::Sidekiq::TimeoutJob
      end

      Redis.client.flushdb
      TestTimeoutWorker.clear
      TestTimeoutWorker.class_variable_set(:@@count, 0)
      TestTimeoutWorker.class_variable_set(:@@callback_count, 0)
    end

    specify 'Sidekiq server terminates long-running jobs' do
      expect(TestTimeoutWorker.jobs.size).to eq(0)

      TestTimeoutWorker.perform_async(1)
      expect(TestTimeoutWorker.jobs.size).to eq(1)

      TestTimeoutWorker.drain
      expect(TestTimeoutWorker.class_variable_get(:@@count)).to eq(0)
    end
  end
end
