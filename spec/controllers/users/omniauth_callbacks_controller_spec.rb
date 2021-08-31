require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:user) { create(:user) }

  describe '#track_registration_event' do
    subject { controller.send(:track_registration_event, :create, via: nil, click_id: nil) }
    it { is_expected.to be_truthy }
  end

  describe '#track_invitation_event' do
    let(:click_id) { "invitation-#{user.uid}" }
    subject { controller.send(:track_invitation_event, click_id) }
    it { is_expected.to be_truthy }
  end
end
