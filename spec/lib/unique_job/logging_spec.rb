require 'rails_helper'

RSpec.describe UniqueJob::Logging do
  let(:instance) do
    Class.new {
      include UniqueJob::Logging
    }.new
  end

  describe '#logger' do
    subject { instance.logger.info 'a' }
    it { is_expected.to be_truthy }
  end
end
