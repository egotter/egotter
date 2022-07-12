require 'rails_helper'

RSpec.describe WorkerErrorHandler do
  let(:instance) { Class.new { include WorkerErrorHandler }.new }

  let(:error) do
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

  describe '#handle_worker_error' do
    subject { instance.handle_worker_error(error, a: 1) }
    it do
      expect(Airbag).to receive(:warn).with(instance_of(String), backtrace: error.backtrace)
      subject
    end
  end
end
