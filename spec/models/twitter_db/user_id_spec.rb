require 'rails_helper'

RSpec.describe TwitterDB::UserId, type: :model do
  describe '.import_uids' do
    subject { described_class.import_uids([1, 2, 3]) }
    it { expect { subject }.to change { described_class.all.size }.by(3) }
  end
end
