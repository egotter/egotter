require 'rails_helper'

RSpec.describe Egotter::Sidekiq::UniqueJobUtil do
  let(:middleware) do
    Class.new do
      include Egotter::Sidekiq::UniqueJobUtil
    end.new
  end

  describe '#perform_if_unique' do
    let(:worker) { double('Worker') }
    let(:args) { [double('Args')] }
    let(:history) { double('History') }

    before { allow(worker).to receive_message_chain(:logger, :debug) }

    context 'The worker implements #unique_key' do
      before { allow(worker).to receive(:unique_key).with(*args).and_return('unique_key') }

      it do
        expect(middleware).to receive(:perform_unique_check).with(worker, args, history, 'unique_key')
        middleware.perform_if_unique(worker, args, history) {}
      end

      context '#perform_unique_check returns true' do
        before { expect(middleware).to receive(:perform_unique_check).with(any_args).and_return(true) }
        it { expect { |b| middleware.perform_if_unique(worker, args, history, &b) }.to yield_control }
      end

      context '#perform_unique_check returns false' do
        before { expect(middleware).to receive(:perform_unique_check).with(any_args).and_return(false) }
        it { expect { |b| middleware.perform_if_unique(worker, args, history, &b) }.not_to yield_control }
      end
    end

    context "The worker doesn't implement #unique_key" do
      before { allow(worker).to receive(:respond_to?).with(:unique_key).and_return(false) }
      it do
        expect(middleware).not_to receive(:perform_unique_check)
        expect { |b| middleware.perform_if_unique(worker, args, history, &b) }.to yield_control
      end
    end
  end

  describe '#perform_unique_check' do
    let(:worker) { double('Worker') }
    let(:args) { [1, 2, 3] }
    let(:queueing_context) { 'server_or_client' }
    let(:history) { Egotter::Sidekiq::RunHistory.new('Worker', queueing_context, 1.minute) }
    let(:unique_key) { 'unique_key' }
    subject { middleware.perform_unique_check(worker, args, history, unique_key) }

    before { allow(worker).to receive_message_chain(:logger, :info) }

    context 'The history includes a job that has the same unique_key' do
      before { allow(history).to receive(:exists?).with(unique_key).and_return(true) }
      it do
        expect(middleware).to receive(:perform_callback).with(worker, :after_skip, args)
        is_expected.to be_falsey
      end
    end

    context 'The history does not include a job that has the same unique_key' do
      before { allow(history).to receive(:exists?).with(unique_key).and_return(false) }
      it do
        expect(history).to receive(:add).with(unique_key)
        is_expected.to be_truthy
      end
    end
  end

  describe '#run_history' do
    let(:worker) { double('Worker') }
    let(:queue_class) { Egotter::Sidekiq::RunHistory }
    let(:queueing_context) { 'server_or_client' }
    subject { middleware.run_history(worker, queue_class, queueing_context) }

    context 'worker.respond_to?(:unique_in) == true' do
      before { allow(worker).to receive(:unique_in).and_return(10.hours) }
      it do
        expect(queue_class).to receive(:new).with(worker.class, queueing_context, 10.hours)
        subject
      end
    end

    context 'worker.respond_to?(:unique_in) == false' do
      before { allow(worker).to receive(:respond_to?).with(:unique_in).and_return(false) }
      it do
        expect(queue_class).to receive(:new).with(worker.class, queueing_context, 1.hour)
        subject
      end
    end
  end
end
