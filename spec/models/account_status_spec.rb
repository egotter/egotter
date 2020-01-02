require 'rails_helper'

RSpec.describe AccountStatus, type: :model do
  describe '#not_found?' do
    let(:ex) { Twitter::Error::NotFound.new('User not found.') }
    subject { described_class.new(ex: ex).not_found? }
    it { is_expected.to be_truthy }
  end

  describe '#no_user_matches?' do
    let(:ex) { Twitter::Error::NotFound.new('No user matches for specified terms.') }
    subject { described_class.new(ex: ex).no_user_matches? }
    it { is_expected.to be_truthy }
  end

  describe '#suspended?' do
    let(:ex) { Twitter::Error::Forbidden.new('User has been suspended.') }
    subject { described_class.new(ex: ex).suspended? }
    it { is_expected.to be_truthy }
  end

  describe '.not_found?' do
    let(:ex) { Twitter::Error::NotFound.new('User not found.') }
    subject { described_class.not_found?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.no_user_matches?' do
    let(:ex) { Twitter::Error::NotFound.new('No user matches for specified terms.') }
    subject { described_class.no_user_matches?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.suspended?' do
    let(:ex) { Twitter::Error::Forbidden.new('User has been suspended.') }
    subject { described_class.suspended?(ex) }
    it { is_expected.to be_truthy }
  end
end
