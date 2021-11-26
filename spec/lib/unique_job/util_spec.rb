require 'rails_helper'

RSpec.describe UniqueJob::Util do
  class TestUniqueJobUtil
    include UniqueJob::Util
  end

  let(:middleware) do
    TestUniqueJobUtil.new
  end

  describe '#perform_if_unique' do
    let(:worker) { double('worker') }
    let(:args) { ['arg1', 'arg2'] }
    let(:unique_key) { 'key' }

    context 'The worker implements #unique_key' do
      before { allow(worker).to receive(:unique_key).with(*args).and_return(unique_key) }

      context 'unique_key is nil' do
        let(:unique_key) { nil }
        it do
          expect(middleware).not_to receive(:check_uniqueness)
          middleware.perform_if_unique(worker, args) {}
        end
      end

      context 'unique_key is empty string' do
        let(:unique_key) { '' }
        it do
          expect(middleware).not_to receive(:check_uniqueness)
          middleware.perform_if_unique(worker, args) {}
        end
      end

      context 'unique_key correct format' do
        context '#check_uniqueness returns true' do
          before { expect(middleware).to receive(:check_uniqueness).with(any_args).and_return(true) }
          it { expect { |b| middleware.perform_if_unique(worker, args, &b) }.to yield_control }
        end

        context '#check_uniqueness returns false' do
          before { expect(middleware).to receive(:check_uniqueness).with(any_args).and_return(false) }
          it { expect { |b| middleware.perform_if_unique(worker, args, &b) }.not_to yield_control }
        end
      end
    end

    context "The worker doesn't implement #unique_key" do
      before { allow(worker).to receive(:respond_to?).with(:unique_key).and_return(false) }
      it do
        expect(middleware).not_to receive(:check_uniqueness)
        expect { |b| middleware.perform_if_unique(worker, args, &b) }.to yield_control
      end
    end
  end

  describe '#check_uniqueness' do
    let(:worker) { double('worker') }
    let(:args) { 'args' }
    let(:history) { double('history') }
    let(:unique_key) { 'unique_key' }
    subject { middleware.check_uniqueness(worker, unique_key) }

    before do
      allow(middleware).to receive(:job_history).with(worker).and_return(history)
      allow(worker).to receive_message_chain(:logger, :info)
    end

    context 'The history includes a job that has the same unique_key' do
      before { allow(history).to receive(:exists?).with(unique_key).and_return(true) }
      it { is_expected.to be_falsey }
    end

    context 'The history does not include a job that has the same unique_key' do
      before { allow(history).to receive(:exists?).with(unique_key).and_return(false) }
      it do
        expect(history).to receive(:add).with(unique_key)
        is_expected.to be_truthy
      end
    end
  end

  describe '#job_history' do
    let(:worker) { double('worker') }
    subject { middleware.job_history(worker) }

    context 'worker.respond_to?(:unique_in) == true' do
      before { allow(worker).to receive(:unique_in).and_return(10.hours) }
      it do
        expect(UniqueJob::JobHistory).to receive(:new).with(worker.class, middleware.class, 10.hours)
        subject
      end
    end

    context 'worker.respond_to?(:unique_in) == false' do
      before { allow(worker).to receive(:respond_to?).with(:unique_in).and_return(false) }
      it do
        expect(UniqueJob::JobHistory).to receive(:new).with(worker.class, middleware.class, 3600)
        subject
      end
    end
  end

  describe '#perform_callback' do

  end

  describe '#truncate' do

  end
end
