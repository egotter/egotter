require 'rails_helper'

RSpec.describe Validations::DuplicateRecordValidator do
  let(:tu) { build(:twitter_user) }
  let(:validator) { Validations::DuplicateRecordValidator.new }

  describe '#same_record_exists?' do
    context 'TwitterUser#latest returns nil' do
      before { allow(tu).to receive(:latest).and_return(nil) }
      it 'returns false' do
        expect(validator.send(:same_record_exists?, tu)).to be_falsey
      end
    end

    context '#same_record? returns true' do
      before do
        allow(tu).to receive(:latest).and_return(tu)
        allow(validator).to receive(:same_record?).and_return(true)
      end
      it 'returns true' do
        expect(validator.send(:same_record_exists?, tu)).to be_truthy
      end
    end

    context '#same_record? returns false' do
      before do
        allow(tu).to receive(:latest).and_return(tu)
        allow(validator).to receive(:same_record?).and_return(false)
      end
      it 'returns false' do
        expect(validator.send(:same_record_exists?, tu)).to be_falsey
      end
    end
  end

  describe '#same_record?' do
    context 'with same record' do
      it 'returns true' do
        expect(validator.send(:same_record?, tu, tu)).to be_truthy
      end
    end
  end

  describe '#recently_created_record_exists?' do
    context 'TwitterUser#latest returns nil' do
      before { allow(tu).to receive(:latest).and_return(nil) }
      it 'returns false' do
        expect(validator.send(:recently_created_record_exists?, tu)).to be_falsey
      end
    end

    context 'TwitterUser#recently_created? returns true' do
      before { allow(tu).to receive(:latest).and_return(Hashie::Mash.new({recently_created?: true})) }
      it 'returns true' do
        expect(validator.send(:recently_created_record_exists?, tu)).to be_truthy
      end
    end
  end
end