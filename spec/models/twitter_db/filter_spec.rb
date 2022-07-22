require 'rails_helper'

RSpec.describe TwitterDB::Filter, type: :model do
  describe '#apply' do
    let(:query) { TwitterDB::User }
    subject { instance.apply(query) }

    described_class::VALUES.each do |value|
      context "#{value} is passed" do
        let(:instance) { described_class.new(value) }
        it { is_expected.to be_truthy }
      end
    end

    context 'verified and protected are passed' do
      let(:instance) { described_class.new('verified,protected') }
      before do
        create(:twitter_db_user, uid: 1, protected: false, verified: false)
        create(:twitter_db_user, uid: 2, protected: false, verified: true)
        create(:twitter_db_user, uid: 3, protected: true, verified: false)
        create(:twitter_db_user, uid: 4, protected: true, verified: true)
      end
      it { expect(subject.map(&:uid)).to eq([4]) }
    end
  end
end
