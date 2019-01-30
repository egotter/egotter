require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe '#silent_transaction' do
    it do
      expect(TwitterUser.new.respond_to?(:silent_transaction)).to be_truthy
    end
  end
end
