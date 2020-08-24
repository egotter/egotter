require 'rails_helper'

RSpec.describe CallCreateFriendshipCount, type: :model do
  let(:instance) { described_class.new }

  describe '#key' do
    subject { instance.key }
    it { is_expected.to eq("#{Rails.env}:CallCreateFriendshipCount:86400:any_ids") }
  end
end
