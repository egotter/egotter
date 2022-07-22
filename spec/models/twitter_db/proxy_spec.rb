require 'rails_helper'

RSpec.describe TwitterDB::Proxy, type: :model do
  describe '#to_a' do
    let(:uids) { [1, 2, 3] }
    let(:instance) { described_class.new(uids) }
    let(:query) { TwitterDB::User }
    subject { instance.limit(10).to_a }
    before { uids.each { |uid| create(:twitter_db_user, uid: uid) } }
    it { expect(subject.map(&:uid)).to eq(uids) }
  end
end
