require 'rails_helper'

RSpec.describe UsageStat, type: :model do
  let(:uid) { rand(1000) }
  let(:statuses) { [build(:mention_status)] }

  describe '#update_with_statuses!' do
    it 'saves one record' do
      expect { UsageStat.update_with_statuses!(uid, statuses) }.to change { UsageStat.all.size }.by(1)
      expect(UsageStat.find_by(uid: uid).mentions).to match(UsageStat.send(:extract_mentions, statuses))
    end
  end
end