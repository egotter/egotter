require 'rails_helper'

RSpec.describe CallDestroyFriendshipCount, type: :model do
  let(:instance) { described_class.new }

  describe '#key' do
    subject { instance.key }
    it { is_expected.to eq("#{Rails.env}:CallDestroyFriendshipCount:86400:any_ids") }
  end
end
