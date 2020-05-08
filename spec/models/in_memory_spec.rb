require 'rails_helper'

RSpec.describe InMemory do
  describe '.redis_hostname' do
    subject { described_class.redis_hostname }
    before { allow(ENV).to receive('[]').with('IN_MEMORY_REDIS_HOST').and_return('specified hostname') }
    it { is_expected.to eq('specified hostname') }
  end

  describe '.used_memory' do
    subject { described_class.used_memory }
    it { is_expected.to include('M') }
  end
end
