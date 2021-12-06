require 'rails_helper'

RSpec.describe ApiClientCacheStore, type: :model do
  let(:instance) { described_class.instance }

  describe '#redis' do
    subject { instance.redis }
    it do
      expect(subject.inspect).to include(':6379/2')
      subject
    end
  end
end
