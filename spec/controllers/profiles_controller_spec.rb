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

  describe '#set_decrypt_names' do
    let(:encrypted_names) { MessageEncryptor.new.encrypt(['a', 'b', 'c'].join(',')) }
    subject { controller.send(:set_decrypt_names, 'b', encrypted_names) }
    it do
      subject
      expect(controller.instance_variable_get(:@indicator_names)).to eq(['a', 'b', 'c'])
      expect(controller.instance_variable_get(:@prev_name)).to eq('a')
      expect(controller.instance_variable_get(:@next_name)).to eq('c')
    end
  end
end
