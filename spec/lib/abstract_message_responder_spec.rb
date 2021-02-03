require 'rails_helper'

describe AbstractMessageResponder do
  let(:klass) do
    Class.new(AbstractMessageResponder) do
      def processor_class
        Processor
      end

      class Processor
        def initialize(*args) end

        def received?
          false
        end
      end
    end
  end
  let(:instance) { klass.new(1, 'text') }

  describe '#respond' do
    subject { instance.respond }
    it { is_expected.to be_falsey }
  end
end

