require 'rails_helper'

describe AlertMessagesConcern, type: :controller do
  controller ApplicationController do
    include AlertMessagesConcern
  end


  shared_context 'user is signed in' do
    let(:user) { create(:user) }
    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  describe '#temporarily_locked_message' do
    subject { controller.temporarily_locked_message }
    it { is_expected.to be_truthy }

    context 'user is signed in' do
      include_context 'user is signed in'
      it { is_expected.to be_truthy }
    end
  end

  describe '#unauthorized_message' do
    subject { controller.unauthorized_message }
    it { is_expected.to be_truthy }

    context 'user is signed in' do
      include_context 'user is signed in'
      it { is_expected.to be_truthy }
    end
  end
end
