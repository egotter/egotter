require 'rails_helper'

RSpec.describe BlockingRelationship, type: :model do
  describe '.import_from' do
    subject { described_class.import_from(1, [2, 3]) }
    it { expect { subject }.to change { described_class.all.size }.by(2) }
  end
end
