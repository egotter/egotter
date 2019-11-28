require 'rails_helper'

RSpec.describe Concerns::TwitterUser::Validation do
  describe '#uid' do
    let(:twitter_user) { build(:twitter_user, uid: uid_value) }
    subject { twitter_user.errors[:uid] }

    before { twitter_user.valid? }

    context 'The uid is empty string' do
      let(:uid_value) { '' }
      it { is_expected.to be_present }
    end

    context 'The uid is nil' do
      let(:uid_value) { nil }
      it { is_expected.to be_present }
    end

    context 'The uid is invalid format' do
      let(:uid_value) { 'name' }
      it { is_expected.to be_present }
    end

    context 'On create' do

    end

    context 'On update' do

    end
  end

  describe '#screen_name' do
    let(:twitter_user) { build(:twitter_user, screen_name: screen_name_value) }
    subject { twitter_user.errors[:screen_name] }

    before { twitter_user.valid? }

    context 'The screen_name is empty string' do
      let(:screen_name_value) { '' }
      it { is_expected.to be_present }
    end

    context 'The screen_name is nil' do
      let(:screen_name_value) { nil }
      it { is_expected.to be_present }
    end

    context 'The screen_name is invalid format' do
      let(:screen_name_value) { 'name-name' }
      it { is_expected.to be_present }
    end
  end

  describe '#raw_attrs_text' do
    let(:twitter_user) { build(:twitter_user, raw_attrs_text: text) }
    subject { twitter_user.errors[:raw_attrs_text] }

    context 'On create' do
      before { twitter_user.valid? }

      context 'The raw_attrs_text is nil' do
        let(:text) { nil }
        it { is_expected.to be_present }
      end

      context 'The raw_attrs_text is empty string' do
        let(:text) { '' }
        it { is_expected.to be_present }
      end

      context 'The raw_attrs_text is invalid format' do
        let(:text) { 'hello' }
        it { is_expected.to be_present }
      end

      context 'The raw_attrs_text is empty json' do
        let(:text) { '{}' }
        it { is_expected.to be_blank }
      end
    end

    context 'On update' do
      before { twitter_user.save!(validate: false) }

      context 'The raw_attrs_text is empty string' do
        context 'The raw_attrs_text is nil' do
          let(:text) { nil }
          it { is_expected.to be_blank }
        end

        context 'The raw_attrs_text is empty string' do
          let(:text) { '' }
          it { is_expected.to be_blank }
        end

        context 'The raw_attrs_text is invalid format' do
          let(:text) { 'hello' }
          it { is_expected.to be_blank }
        end

        context 'The raw_attrs_text is empty json' do
          let(:text) { '{}' }
          it { is_expected.to be_blank }
        end
      end
    end
  end

  # describe '#valid?' do
  #   subject { twitter_user.valid? }
  #
  #   context 'on create' do
  #     it 'uses Validations::DuplicateRecordValidator' do
  #       expect_any_instance_of(Validations::DuplicateRecordValidator).to receive(:validate)
  #       is_expected.to be_truthy
  #     end
  #   end
  #
  #   context 'on update' do
  #     before do
  #       twitter_user.save!
  #       twitter_user.uid = twitter_user.uid.to_i * 2
  #     end
  #     it 'does not use Validations::DuplicateRecordValidator' do
  #       expect_any_instance_of(Validations::DuplicateRecordValidator).not_to receive(:validate)
  #       is_expected.to be_truthy
  #     end
  #   end
  # end
end