require 'rails_helper'

RSpec.describe SharesController, type: :controller do
  describe '#egotter_share_url' do
    subject { controller.send(:egotter_share_url) }
    it { is_expected.to be_truthy }
  end
end
