require 'rails_helper'

RSpec.describe Logging do
  controller ApplicationController do
    include Logging
  end

  describe '#create_access_day' do
    let(:user) { create(:user) }
    subject { controller.create_access_day }
    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end
    it do
      expect(CreateAccessDayWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#track_event' do
    subject { controller.track_event('name', 'properties') }
    it do
      expect(controller).to receive_message_chain(:ahoy, :track).with('name', 'properties')
      subject
    end
  end
end
