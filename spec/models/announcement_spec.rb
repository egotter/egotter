require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe '.list' do
    subject { described_class.list }

    before { 15.times { create(:announcement) } }

    it { expect(subject.size).to eq(12) }
  end
end
