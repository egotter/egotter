require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:user) { create(:user) }

  describe '#twitter' do
    let(:ahoy) { double('ahoy') }
    subject { controller.twitter }
    before do
      allow(controller).to receive(:create_or_update_user).and_return([user, :create])
      allow(controller).to receive(:performed?)
      allow(controller).to receive(:ahoy).and_return(ahoy)
      allow(controller).to receive(:after_callback_path).with(user, :create).and_return('path')
    end
    it do
      expect(controller).to receive(:sign_in).with(user, event: :authentication)
      expect(ahoy).to receive(:authenticate).with(user)
      expect(controller).to receive(:track_registration_event).with(:create, via: nil, click_id: nil)
      expect(controller).to receive(:update_twitter_db_user).with(user.uid)
      expect(controller).to receive(:request_creating_twitter_user).with(user.uid)
      expect(controller).to receive(:follow_egotter).with(user)
      expect(controller).to receive(:redirect_to).with('path')
      subject
    end
  end

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
