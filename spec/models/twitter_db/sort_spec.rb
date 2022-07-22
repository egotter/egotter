require 'rails_helper'

RSpec.describe TwitterDB::Sort, type: :model do
  describe '#apply' do
    let(:query) { TwitterDB::User }

    described_class::VALUES.each do |value|
      context "#{value} is passed" do
        let(:instance) { described_class.new(value) }
        subject { instance.apply(query, [1, 2, 3]) }
        it { is_expected.to be_truthy }
      end
    end

    context 'desc and valid uids are passed' do
      let(:instance) { described_class.new('desc') }
      subject { instance.apply(query, [3, 1, 2]) }
      before { 3.times { |n| create(:twitter_db_user, uid: n + 1) } }
      it { is_expected.to eq([3, 1, 2]) }
    end
  end
end
