require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Validation do
  subject(:twitter_user) { build(:twitter_user) }

  describe '#valid_uid?' do
    subject { twitter_user.valid_uid? }

    context 'with not a number' do
      it 'returns false' do
        twitter_user.uid = '110a'
        is_expected.to be_truthy # NOTE: '110a' is automatically converted to 110
      end
    end

    context 'with a number' do
      it 'returns true' do
        twitter_user.uid = 100
        is_expected.to be_truthy
      end
    end
  end

  describe '#valid_screen_name?' do
    subject { twitter_user.valid_screen_name? }

    context 'it has special chars' do
      it 'returns false' do
        (%w(! " # $ % & ' - = ^ ~ ¥ \\ | @ ; + : * [ ] { } < > / ?) + %w[( )]).each do |c|
          twitter_user.screen_name = c * 10
          is_expected.to be_falsy
        end
      end
    end

    context 'it has normal chars' do
      it 'returns true' do
        twitter_user.screen_name = 'ego_tter'
        is_expected.to be_truthy
      end
    end
  end

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