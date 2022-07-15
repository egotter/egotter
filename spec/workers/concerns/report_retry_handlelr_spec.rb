require 'rails_helper'

RSpec.describe ReportRetryHandler do
  let(:instance) do
    Class.new do
      include ReportRetryHandler

      def self.perform_in(*args) end

      def logger
        Rails.logger
      end
    end.new
  end

  describe '#retry_current_report' do
    let(:options) { {a: 1} }
    subject { instance.retry_current_report(1, options) }

    it do
      expect(instance.class).to receive(:perform_in).with(instance_of(Integer), 1, options)
      subject
    end
  end
end
