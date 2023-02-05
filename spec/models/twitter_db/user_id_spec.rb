require 'rails_helper'

RSpec.describe TwitterDB::UserId, type: :model do
  describe '.import_uids' do
    subject { described_class.import_uids([1, 2, 3]) }
    it { expect { subject }.to change { described_class.all.size }.by(3) }
  end

  describe '.deadlock_error?' do
    let(:error) { RuntimeError.new }
    subject { described_class.deadlock_error?(error) }
    it { is_expected.to be_falsey }
  end
end
