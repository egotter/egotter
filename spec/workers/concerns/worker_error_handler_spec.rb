require 'rails_helper'

RSpec.describe WorkerErrorHandler do
  let(:instance) { Class.new { include WorkerErrorHandler }.new }

  describe '#handle_worker_error' do
    let(:error) { 'error' }
    subject { instance.handle_worker_error(error, a: 1) }
    it do
      expect(Airbag).to receive(:exception).with(error, method: :handle_worker_error, a: 1)
      subject
    end
  end
end
