require 'rails_helper'

RSpec.describe TwitterRequest, type: :model do
  let(:instance) { described_class.new(:method_name) }

  describe '#perform' do
    let(:block) { Proc.new { 'block_result' } }
    subject { instance.perform(&block) }

    it { is_expected.to eq('block_result') }

    context 'exception is raised' do
      let(:error) { RuntimeError.new('error') }
      let(:block) { Proc.new { raise error } }

      it { expect { subject }.to raise_error(error) }

      context 'the exception is not retryable' do
        it do
          expect(instance).to receive(:handle_exception).with(error).and_call_original
          expect { subject }.to raise_error(error)
        end
      end

      context 'the exception is retryable' do
        let(:retry_count) { described_class::MAX_RETRIES + 1 }
        before { allow(ServiceStatus).to receive(:retryable_error?).with(error).and_return(true) }
        it do
          expect(instance).to receive(:handle_exception).with(error).exactly(retry_count).times.and_call_original
          expect { subject }.to raise_error(ApiClient::RetryExhausted)
          expect(instance.instance_variable_get(:@retries)).to eq(retry_count)
        end
      end
    end
  end

  describe '#handle_exception' do
    let(:error) { RuntimeError.new('error') }
    subject { instance.send(:handle_exception, error) }

    context 'exception is retryable' do
      before { allow(ServiceStatus).to receive(:retryable_error?).with(error).and_return(true) }
      it { expect { subject }.not_to raise_error }
    end

    context 'exception is not retryable' do
      it { expect { subject }.to raise_error(error) }
    end
  end
end
