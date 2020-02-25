require 'rails_helper'

RSpec.describe CallCreateDirectMessageEventCount, type: :model do
  %i(
      increment
      raised
      raised_ttl
      raised?
      rate_limited?
    ).each do |method_name|
    describe "##{method_name}" do
      it do
        expect(described_class.send(method_name)).to eq(described_class.new.send(method_name))
      end
    end
  end
end
