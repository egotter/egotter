require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:user) { create(:user) }
  let(:visit) { double(id: 'visit-id') }

  describe '#track_registration_event' do
    subject { controller.send(:track_registration_event, user, :create, via: nil, click_id: nil) }
    before { allow(controller).to receive(:current_visit).and_return(visit) }
    it { is_expected.to be_truthy }
  end

  describe '#track_invitation_event' do
    let(:click_id) { "invitation-#{user.uid}" }
    subject { controller.send(:track_invitation_event, user, click_id) }
    before { allow(controller).to receive(:current_visit).and_return(visit) }
    it { is_expected.to be_truthy }
  end
end
