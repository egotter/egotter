require 'rails_helper'

RSpec.describe ProfilesController, type: :controller do
  let(:screen_name) { 'sn' }
  let(:twitter_db_user) { create(:twitter_user, screen_name: screen_name) }

  before do
    allow(TwitterDB::User).to receive(:find_by).with(screen_name: screen_name).and_return(twitter_db_user)
  end

  describe 'GET #show' do
    subject { get :show, params: {screen_name: screen_name} }
    it { is_expected.to have_http_status(:success) }
  end

  describe '#decrypt_names' do
    let(:encrypted_names) { MessageEncryptor.new.encrypt(['a', 'b', 'c'].join(',')) }
    subject { controller.send(:decrypt_names, 'b', encrypted_names) }
    it { is_expected.to eq(['a', 'c']) }
  end
end
