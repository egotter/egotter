require 'rails_helper'

RSpec.describe LoggingWrapper do
  class TestLoggingWrapper
    prepend LoggingWrapper

    def perform(*)
      'result'
    end
  end

  class TestLoggingWrapperWithStatementInvalid
    prepend LoggingWrapper

    def perform(*)
      raise ActiveRecord::StatementInvalid
    end
  end

  class TestLoggingWrapperWithRuntimeError
    prepend LoggingWrapper

    def perform(*)
      raise RuntimeError
    end
  end

  describe '#perform' do
    let(:instance) { TestLoggingWrapper.new }
    subject { instance.perform }
    it { is_expected.to eq('result') }

    context 'ActiveRecord::StatementInvalid is raised' do
      let(:instance) { TestLoggingWrapperWithStatementInvalid.new }
      it { expect { subject }.to raise_error(described_class::StatementInvalid) }
    end

    context 'RuntimeError is raised' do
      let(:instance) { TestLoggingWrapperWithRuntimeError.new }
      it do
        expect(Airbag).to receive(:exception).with(instance_of(RuntimeError), args: [])
        is_expected.to be_nil
      end
    end
  end
end
