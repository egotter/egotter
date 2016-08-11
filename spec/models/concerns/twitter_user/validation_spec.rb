require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Validation do
  subject(:tu) { build(:twitter_user) }

  describe '#valid_uid?' do
    context 'with not a number' do
      it 'returns false' do
        tu.uid = '110a'
        expect(tu.valid_uid?).to be_falsy
      end
    end

    context 'with a number' do
      it 'returns true' do
        tu.uid = 100
        expect(tu.valid_uid?).to be_truthy
      end
    end
  end

  describe '#valid_screen_name?' do
    context 'it has special chars' do
      it 'returns false' do
        (%w(! " # $ % & ' - = ^ ~ ¥ \\ | @ ; + : * [ ] { } < > / ?) + %w[( )]).each do |c|
          tu.screen_name = c * 10
          expect(tu.valid_screen_name?).to be_falsy
        end
      end
    end

    context 'it has normal chars' do
      it 'returns true' do
        tu.screen_name = 'ego_tter'
        expect(tu.valid_screen_name?).to be_truthy
      end
    end
  end

  describe '#valid?' do
    context 'on create' do
      it 'uses Validations::DuplicateRecordValidator' do
        expect_any_instance_of(Validations::DuplicateRecordValidator).to receive(:validate)
        expect(tu.valid?).to be_truthy
      end
    end

    context 'on update' do
      before do
        tu.save!
        tu.uid = tu.uid.to_i * 2
      end
      it 'does not use Validations::DuplicateRecordValidator' do
        expect_any_instance_of(Validations::DuplicateRecordValidator).not_to receive(:validate)
        expect(tu.valid?).to be_truthy
      end
    end
  end
end