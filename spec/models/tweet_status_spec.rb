require 'rails_helper'

RSpec.describe TweetStatus, type: :model do
  describe '.no_status_found?' do
    let(:ex) { Twitter::Error::NotFound.new('No status found with that ID.') }
    subject { described_class.no_status_found?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.not_authorized?' do
    let(:ex) { Twitter::Error::Forbidden.new('Sorry, you are not authorized to see this status.') }
    subject { described_class.not_authorized?(ex) }
    it { is_expected.to be_truthy }
  end

  describe '.already_favorited?' do
    let(:ex) { Twitter::Error::AlreadyFavorited.new }
    subject { described_class.already_favorited?(ex) }
    it { is_expected.to be_truthy }
  end
end
