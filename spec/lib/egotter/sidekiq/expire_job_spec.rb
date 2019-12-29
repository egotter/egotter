require 'rails_helper'

RSpec.describe Egotter::Sidekiq::ExpireJob do
  let(:middleware) { described_class.new }

  describe '#call' do
    let(:worker) { double('Worker') }
    let(:enqueued_at) { 'ok' }
    let(:msg) { {'args' => [1, 'enqueued_at' => 'time']} }
    let(:expire_in) { 1.minute }

    before { allow(middleware).to receive(:pick_enqueued_at).with(msg).and_return(enqueued_at) }

    context 'The worker implements #expire_in' do
      before { allow(worker).to receive(:expire_in).and_return(expire_in) }

      it do
        expect(middleware).to receive(:perform_expire_check).with(worker, msg['args'], expire_in, enqueued_at)
        middleware.call(worker, msg, nil) {}
      end

      context '#perform_expire_check returns true' do
        before { expect(middleware).to receive(:perform_expire_check).with(any_args).and_return(true) }
        it { expect { |b| middleware.call(worker, msg, nil, &b) }.to yield_control }
      end

      context '#perform_expire_check returns false' do
        before { expect(middleware).to receive(:perform_expire_check).with(any_args).and_return(false) }
        it { expect { |b| middleware.call(worker, msg, nil, &b) }.not_to yield_control }
      end
    end

    context "The worker doesn't implement #expire_in" do
      before { allow(worker).to receive(:respond_to?).with(:expire_in).and_return(false) }
      it do
        expect(middleware).not_to receive(:perform_expire_check)
        expect { |b| middleware.call(worker, msg, nil, &b) }.to yield_control
      end
    end
  end

  describe '#perform_expire_check' do
    let(:worker) { double('Worker') }
    let(:args) { [1, 'enqueued_at' => enqueued_at] }
    let(:expire_in) { 1.minute }
    subject { middleware.perform_expire_check(worker, args, expire_in, enqueued_at) }

    before { allow(worker).to receive(:logger).and_return(Logger.new(nil)) }

    context 'enqueued_at is nil' do
      let(:enqueued_at) { nil }
      it { is_expected.to be_truthy }
    end

    context 'enqueued_at < Time.zone.now - expire_in' do
      let(:enqueued_at) { Time.zone.now - expire_in - 1.second }
      it do
        expect(middleware).to receive(:perform_callback).with(worker, :after_expire, args)
        is_expected.to be_falsey
      end
    end
  end

  describe '#pick_enqueued_at' do
    let(:msg) { {'args' => args, 'enqueued_at' => time} }
    subject { middleware.pick_enqueued_at(msg) }

    before { allow(middleware).to receive(:parse_time).with(time).and_return('parsed') }

    context 'args has enqueued_at' do
      let(:time) { 'at' }
      let(:args) { [1, 'enqueued_at' => time] }
      it { is_expected.to eq('parsed') }
    end

    context "args doesn't have enqueued_at" do
      let(:time) { 'at' }
      let(:args) { [1] }
      it { is_expected.to eq('parsed') }
    end
  end

  describe '#parse_time' do
    let(:time) { Time.zone.now }
    subject { middleware.parse_time(value) }

    context 'The value is a floating point number' do
      let(:value) { time.to_f }
      it { is_expected.to be_within(1.second).of(time) }
    end

    context 'The value is a string' do
      let(:value) { time.to_s }
      it { is_expected.to be_within(1.second).of(time) }
    end

    context 'The value is something invalid' do
      let(:value) { nil }
      it { is_expected.to be_nil }
    end
  end

  context 'Server side job running' do
    class TestExpireWorker
      include Sidekiq::Worker
      sidekiq_options queue: 'test', retry: 0, backtrace: false

      @@count = 0
      @@callback_count = 0

      def expire_in
        1.minute
      end

      def after_expire(*args)
        @@callback_count += 1
      end

      def perform(*args)
        @@count += 1
      end
    end

    before do
      Sidekiq::Testing.server_middleware do |chain|
        chain.add Egotter::Sidekiq::ExpireJob
      end

      Redis.client.flushdb
      TestExpireWorker.clear
      TestExpireWorker.class_variable_set(:@@count, 0)
      TestExpireWorker.class_variable_set(:@@callback_count, 0)
    end

    specify "Sidekiq server doesn't run jobs that have a expired enqueued_at" do
      expect(TestExpireWorker.jobs.size).to eq(0)

      TestExpireWorker.perform_async(1, enqueued_at: Time.zone.now)
      expect(TestExpireWorker.jobs.size).to eq(1)

      TestExpireWorker.perform_async(1, enqueued_at: 1.hour.ago)
      expect(TestExpireWorker.jobs.size).to eq(2)

      TestExpireWorker.drain
      expect(TestExpireWorker.jobs.size).to eq(0)
      expect(TestExpireWorker.class_variable_get(:@@count)).to eq(1)
      expect(TestExpireWorker.class_variable_get(:@@callback_count)).to eq(1)
    end

    specify 'Sidekiq server expires jobs with no enqueued_at specified' do
      expect(TestExpireWorker.jobs.size).to eq(0)

      TestExpireWorker.perform_async(1)
      expect(TestExpireWorker.jobs.size).to eq(1)

      travel 1.hour

      TestExpireWorker.drain
      expect(TestExpireWorker.jobs.size).to eq(0)
      expect(TestExpireWorker.class_variable_get(:@@count)).to eq(0)
      expect(TestExpireWorker.class_variable_get(:@@callback_count)).to eq(1)
    end
  end
end
