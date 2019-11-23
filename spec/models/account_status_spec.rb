require 'rails_helper'

RSpec.describe AccountStatus, type: :model do

  describe '#not_found?' do
    let(:ex) { Twitter::Error::NotFound.new('User not found.') }
    let(:status) { AccountStatus.new(ex: ex) }
    it { expect(status.not_found?).to be_truthy }
  end

  describe '#suspended?' do
    let(:ex) { Twitter::Error::Forbidden.new('User has been suspended.') }
    let(:status) { AccountStatus.new(ex: ex) }
    it { expect(status.suspended?).to be_truthy }
  end

  describe '.not_found?' do
    let(:ex) { Twitter::Error::NotFound.new('User not found.') }
    it { expect(AccountStatus.not_found?(ex)).to be_truthy }
  end

  describe '.suspended?' do
    let(:ex) { Twitter::Error::Forbidden.new('User has been suspended.') }
    it { expect(AccountStatus.suspended?(ex)).to be_truthy }
  end
end
