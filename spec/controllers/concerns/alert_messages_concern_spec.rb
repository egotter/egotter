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
end
