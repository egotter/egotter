require 'rails_helper'

RSpec.describe SearchRequest, type: :model do
  let(:user) { create(:user) }
  let(:uid) { 1 }
  let(:screen_name) { 'name' }
  let(:request) do
    create(
        :search_request,
        user_id: user.id,
        uid: uid,
        screen_name: screen_name,
        properties: {remaining_count: 3}
    )
  end

  describe '#perform' do
    let(:client) { double('client') }
    let(:twitter) { double('twitter') }
    let(:target_user) { {id: 2} }
    subject { request.perform }

    before do
      allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      allow(user).to receive(:api_client).and_return(client)
      allow(client).to receive(:twitter).and_return(twitter)
    end

    it do
      expect(client).to receive(:user).with(uid).and_return(target_user)
      expect(twitter).to receive(:user_timeline).with(target_user[:id], count: 1)
      subject
      expect(request.status).to eq('ok')
    end
  end
end
