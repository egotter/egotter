require 'rails_helper'

RSpec.describe TweetStatus, type: :model do
  describe '.no_status_found?' do
    let(:ex) { Twitter::Error::NotFound.new('No status found with that ID.') }
    subject { described_class.no_status_found?(ex) }
    it { is_expected.to be_truthy }
  end

end
