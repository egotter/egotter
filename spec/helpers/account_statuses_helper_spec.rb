require 'rails_helper'

RSpec.describe AccountStatusesHelper, type: :helper do
  let(:client) { double('client') }

  describe '#collect_suspended_uids' do
    let(:uids) { [1, 2, 3, 4] }
    let(:users) { [{id: 1, suspended: false}, {id: 3, suspended: true}, {id: 4, suspended: false}] }
    subject { helper.collect_suspended_uids(client, uids) }
    before { allow(client).to receive(:users).with(uids).and_return(users) }
    it { is_expected.to eq([2, 3]) }
  end
end
