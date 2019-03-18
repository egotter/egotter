require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Validation do
  subject(:twitter_user) { build(:twitter_user) }

  describe '#valid?' do
    subject { twitter_user.valid? }

    context 'on create' do
      it 'uses Validations::DuplicateRecordValidator' do
        expect_any_instance_of(Validations::DuplicateRecordValidator).to receive(:validate)
        is_expected.to be_truthy
      end
    end

    context 'on update' do
      before do
        twitter_user.save!
        twitter_user.uid = twitter_user.uid.to_i * 2
      end
      it 'does not use Validations::DuplicateRecordValidator' do
        expect_any_instance_of(Validations::DuplicateRecordValidator).not_to receive(:validate)
        is_expected.to be_truthy
      end
    end
  end
end