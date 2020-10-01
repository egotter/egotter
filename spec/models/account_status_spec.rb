require 'rails_helper'

RSpec.describe AccountStatus, type: :model do
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

  describe '.forbidden?' do
    let(:ex) { Twitter::Error::Forbidden.new }
    subject { described_class.forbidden?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.suspended?' do
    let(:ex) { Twitter::Error::Forbidden.new('User has been suspended.') }
    subject { described_class.suspended?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.blocked?' do
    let(:ex) { Twitter::Error::Unauthorized.new("You have been blocked from viewing this user's profile.") }
    subject { described_class.blocked?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.protected?' do
    let(:ex) { Twitter::Error::Unauthorized.new("Not authorized.") }
    subject { described_class.protected?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.unauthorized?' do
    let(:ex) { Twitter::Error::Unauthorized.new("Invalid or expired token.") }
    subject { described_class.unauthorized?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.invalid_or_expired_token?' do
    let(:ex) { Twitter::Error::Unauthorized.new("Invalid or expired token.") }
    subject { described_class.invalid_or_expired_token?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.could_not_authenticate_you?' do
    let(:ex) { Twitter::Error::Unauthorized.new("Could not authenticate you.") }
    subject { described_class.could_not_authenticate_you?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.bad_authentication_data?' do
    let(:ex) { Twitter::Error::BadRequest.new("Bad Authentication data.") }
    subject { described_class.bad_authentication_data?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.too_many_requests?' do
    subject { described_class.too_many_requests?(ex) }
    [
        Twitter::Error::TooManyRequests.new("Rate limit exceeded"),
        Twitter::Error::TooManyRequests.new,
    ].each do |error_value|
      context "#{error_value} is raised" do
        let(:ex) { error_value }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.temporarily_locked?' do
    let(:ex) { Twitter::Error::Forbidden.new('To protect our users from spam and other malicious activity, this account is temporarily locked. Please log in to https://twitter.com to unlock your account.') }
    subject { described_class.temporarily_locked?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.your_account_suspended?' do
    let(:ex) { Twitter::Error::Forbidden.new("Your account is suspended and is not permitted to access this feature.") }
    subject { described_class.your_account_suspended?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.blocked_from_following?' do
    let(:ex) { Twitter::Error::Forbidden.new('You have been blocked from following this account at the request of the user.') }
    subject { described_class.blocked_from_following?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.unable_to_follow?' do
    let(:ex) { Twitter::Error::Forbidden.new("You are unable to follow more people at this time. Learn more <a href='http://support.twitter.com/articles/66885-i-can-t-follow-people-follow-limits'>here</a>.") }
    subject { described_class.unable_to_follow?(ex) }
    it { is_expected.to be_truthy }
  end
end
