require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  let(:user) { create(:user, with_credential_token: true) }

  describe 'POST #update_instance_id' do
    let(:params) { {uid: user.uid, access_token: user.token, instance_id: 'instance_id'} }
    subject { post :update_instance_id, params: params }

    before do
      allow(User).to receive(:find_by).with(uid: user.uid.to_s, token: user.token)
      allow(controller).to receive(:verified_android_request?).and_return(true)
      controller.instance_variable_set(:@user, user)
    end

    context 'verified request' do
      let(:response_body) { {json: true} }
      before do
        allow(User).to receive(:find_by).with(uid: user.uid.to_s, token: user.token)
        allow(controller).to receive(:verified_android_request?).and_return(true)
      end

      it do
        expect(controller).to receive(:enqueue_create_periodic_report_job).with(user).and_return('jid')
        expect(controller).to receive(:build_android_response).with(user, 'jid').and_return(response_body)
        is_expected.to have_http_status(:ok)
        expect(response.body).to eq(response_body.to_json)
        expect(user.credential_token.instance_id).to eq('instance_id')
      end
    end

    context 'invalid request' do
      before { allow(controller).to receive(:verified_android_request?).and_return(false) }

      it do
        is_expected.to have_http_status(:not_found)
        expect(response.body).to eq({found: false}.to_json)
      end
    end
  end

  describe '#verified_android_request?' do
    subject { controller.send(:verified_android_request?) }

    before do
      %i(uid access_token instance_id).each do |key|
        allow(controller.params).to receive(:[]).with(key).and_return(key.to_s)
      end
      allow(User).to receive(:find_by).with(uid: 'uid', token: 'access_token').and_return(user)
    end

    it do
      is_expected.to be_truthy
      expect(controller.instance_variable_get(:@user).id).to eq(user.id)
    end
  end

  describe '#enqueue_create_periodic_report_job' do
    let(:request) { CreatePeriodicReportRequest.create(user_id: user.id) }
    subject { controller.send(:enqueue_create_periodic_report_job, user) }
    before do
      allow(CreatePeriodicReportRequest).to receive(:create).with(user_id: user.id).and_return(request)
    end
    it do
      expect(CreateAndroidRequestedPeriodicReportWorker).to receive(:perform_async).with(request.id, user_id: user.id, requested_by: 'android_app')
      subject
    end
  end

  describe '#build_android_response' do
    let(:return_value) do
      {
          uid: user.uid,
          screen_name: user.screen_name,
          version_code: ENV['ANDROID_VERSION_CODE'],
          found: true,
          jid: 'jid'
      }
    end
    subject { controller.send(:build_android_response, user, 'jid') }

    it { is_expected.to eq(return_value) }

    context 'twitter_user is found' do
      let(:twitter_user) { build(:twitter_user, with_relations: false) }
      before do
        allow(TwitterUser).to receive(:latest_by).with(uid: user.uid).and_return(twitter_user)
        allow(twitter_user).to receive(:summary_counts).and_return(one_sided_friends: 1)
      end
      it do
        is_expected.to eq(return_value.merge(one_sided_friends: 1))
      end
    end
  end
end
