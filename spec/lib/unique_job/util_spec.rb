require 'rails_helper'

RSpec.describe UniqueJob::Util do
  module TestUniqueJob
    class TestClass
      include UniqueJob::Util
    end
  end

  let(:middleware) do
    TestUniqueJob::TestClass.new
  end

  describe '#perform_if_unique' do
    let(:worker) { double('worker') }
    let(:args) { [double('args')] }

    context 'The worker implements #unique_key' do
      context 'unique_key is nil' do
        before { allow(worker).to receive(:unique_key).with(*args).and_return(nil) }
        it do
          expect(middleware).not_to receive(:perform_unique_check)
          middleware.perform_if_unique(worker, args) {}
        end
      end

      context 'unique_key is empty string' do
        before { allow(worker).to receive(:unique_key).with(*args).and_return('') }
        it do
          expect(middleware).not_to receive(:perform_unique_check)
          middleware.perform_if_unique(worker, args) {}
        end
      end

      context 'unique_key correct format' do
        before { allow(worker).to receive(:unique_key).with(*args).and_return('unique_key') }

        context '#perform_unique_check returns true' do
          before { expect(middleware).to receive(:perform_unique_check).with(any_args).and_return(true) }
          it { expect { |b| middleware.perform_if_unique(worker, args, &b) }.to yield_control }
        end

        context '#perform_unique_check returns false' do
          before { expect(middleware).to receive(:perform_unique_check).with(any_args).and_return(false) }
          it { expect { |b| middleware.perform_if_unique(worker, args, &b) }.not_to yield_control }
        end
      end
    end

    context "The worker doesn't implement #unique_key" do
      before { allow(worker).to receive(:respond_to?).with(:unique_key).and_return(false) }
      it do
        expect(middleware).not_to receive(:perform_unique_check)
        expect { |b| middleware.perform_if_unique(worker, args, &b) }.to yield_control
      end
    end
  end

  describe '#perform_unique_check' do
    let(:worker) { double('worker') }
    let(:args) { 'args' }
    let(:history) { double('history') }
    let(:unique_key) { 'unique_key' }
    subject { middleware.perform_unique_check(worker, args, unique_key) }

    before do
      allow(middleware).to receive(:job_history).with(worker).and_return(history)
      allow(worker).to receive_message_chain(:logger, :info)
    end

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

  describe '#job_history' do
    let(:worker) { double('worker') }
    subject { middleware.job_history(worker) }

    context 'worker.respond_to?(:unique_in) == true' do
      before { allow(worker).to receive(:unique_in).and_return(10.hours) }
      it do
        expect(UniqueJob::JobHistory).to receive(:new).with(worker.class, middleware.class.name.demodulize, 10.hours)
        subject
      end
    end

    context 'worker.respond_to?(:unique_in) == false' do
      before { allow(worker).to receive(:respond_to?).with(:unique_in).and_return(false) }
      it do
        expect(UniqueJob::JobHistory).to receive(:new).with(worker.class, middleware.class.name.demodulize, 3600)
        subject
      end
    end
  end

  describe '#perform_callback' do

  end

  describe '#truncate' do

  end

  describe '#class_name' do
    subject { middleware.class_name }
    it { is_expected.to eq('TestClass') }
  end
end
