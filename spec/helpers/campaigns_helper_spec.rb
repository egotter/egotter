require 'rails_helper'

RSpec.describe CampaignsHelper, type: :helper do
  describe '#campaign_params' do
    subject { helper.campaign_params('name') }
    it { is_expected.to be_truthy }
  end
end
