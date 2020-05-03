require 'rails_helper'

RSpec.describe CreateTwitterUserWorker do
  describe '#unique_key' do
    let(:worker) { described_class.new }
    it do
      expect(worker.unique_key(1, {user_id: 2, uid: 3})).to eq('2-3')
      expect(worker.unique_key(1, {'user_id' => 2, 'uid' => 3})).to eq('2-3')
    end
  end
end
