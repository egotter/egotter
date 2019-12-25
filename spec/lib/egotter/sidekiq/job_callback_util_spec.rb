require 'rails_helper'

RSpec.describe Egotter::Sidekiq::JobCallbackUtil do
  let(:middleware) do
    Class.new do
      include Egotter::Sidekiq::JobCallbackUtil
    end.new
  end

  describe '#perform_callback' do
    let(:worker) { double('Worker') }
    let(:args) { [1, 2, 3] }
    subject { middleware.perform_callback(worker, :this_is_callback, args) }

    context 'The worker does not have a callback method' do
      it { expect { subject }.not_to raise_error }
    end

    context 'The number of parameters of the callback method is zero' do
      before do
        def worker.this_is_callback
          @called = true
        end
      end
      it do
        expect { subject }.not_to raise_error
        expect(worker.instance_variable_get(:@called)).to be_truthy
      end
    end

    context 'The number of parameters of the callback method is the same as the number of arguments' do
      before do
        def worker.this_is_callback(a, b, c)
          @called = true
        end
      end
      it do
        expect { subject }.not_to raise_error
        expect(worker.instance_variable_get(:@called)).to be_truthy
      end
    end

    context 'The number of parameters of the callback method is 1 and the kind of the first parameter is :rest' do
      before do
        def worker.this_is_callback(*args)
        end
      end
      it { expect { subject }.not_to raise_error }
    end

    context 'The number of parameters of the callback method is NOT the same as the number of arguments' do
      before do
        def worker.this_is_callback(a, b)
        end
      end
      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end
end
