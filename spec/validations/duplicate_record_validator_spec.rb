require 'rails_helper'

RSpec.describe Validations::DuplicateRecordValidator do
  let(:tu) { build(:twitter_user) }
  let(:validator) { Validations::DuplicateRecordValidator.new }

  describe '#validate' do
    context 'TwitterUser::latest returns nil' do
      before { allow(TwitterUser).to receive(:latest).and_return(nil) }
      it 'returns nil' do
        expect(validator.validate(tu)).to be_nil
      end
    end
  end
end