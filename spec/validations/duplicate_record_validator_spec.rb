require 'rails_helper'

RSpec.describe Validations::DuplicateRecordValidator do
  let(:twitter_user) { build(:twitter_user) }
  let(:validator) { Validations::DuplicateRecordValidator.new }

  describe '#validate' do
    context 'TwitterUser::latest returns nil' do
      before { allow(TwitterUser).to receive(:latest_by).with(uid: twitter_user.uid).and_return(nil) }
      it 'returns nil' do
        expect(validator.validate(twitter_user)).to be_nil
      end
    end
  end
end