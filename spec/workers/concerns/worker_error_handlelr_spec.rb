require 'rails_helper'

RSpec.describe WorkerErrorHandler do
  let(:dummy_class) do
    Class.new do
      include WorkerErrorHandler

      def logger=(l)
        @logger = l
      end

      def logger
        @logger
      end
    end
  end
  let(:instance) { dummy_class.new }
  let(:logger) { Logger.new(STDOUT) }

  let(:nested_error) do
    err = nil
    begin
      begin
        raise 'first'
      rescue => e
        raise 'second'
      end
    rescue => e
      err = e
    end
    err
  end

  before do
    instance.logger = logger
  end

  describe '#handle_worker_error' do
    subject { instance.handle_worker_error(nested_error, a: 1) }
    it do
      expect(instance).to receive(:_print_exception).with(nested_error, a: 1)
      # expect(SendErrorMessageToSlackWorker).to receive(:perform_async).with(any_args)
      subject
    end
  end

  describe '#_print_exception' do
    subject { instance.send(:_print_exception, nested_error, {}) }
    it do
      expect(logger).to receive(:warn).with(instance_of(String)).exactly(2).times
      expect(logger).to receive(:info).with(instance_of(String)).exactly(2).times
      subject
    end
  end
end
