require 'rails_helper'

describe ValidationConcern, type: :controller do
  controller ApplicationController do
    include ValidationConcern
    include JobQueueingConcern # for #update_twitter_db_user
  end

  let(:user) { create(:user) }
  let(:client) { double('client') }

  shared_context 'user is signed in' do
    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  shared_context 'user is not signed in' do
    let(:user) { nil }
    before do
      allow(controller).to receive(:user_signed_in?).and_return(false)
      allow(controller).to receive(:current_user).and_return(nil)
    end
  end

  shared_context 'user is authorized' do
    before { user.update(authorized: true) }
  end

  shared_context 'user is not authorized' do
    before { user.update(authorized: false) }
  end

  describe '#require_login!' do
    shared_context 'request is xhr' do
      before { allow(controller.request).to receive(:xhr?).and_return(true) }
    end

    shared_context 'request is not xhr' do
      before { allow(controller.request).to receive(:xhr?).and_return(false) }
    end

    subject { controller.require_login! }

    context 'user is signed in' do
      include_context 'user is signed in'
      it { is_expected.to be_nil }
    end

    context 'user is not signed in and request is xhr' do
      include_context 'user is not signed in'
      include_context 'request is xhr'
      it do
        expect(controller).to receive(:render).with(any_args)
        subject
      end
    end

    context 'user is not signed in and request is not xhr' do
      include_context 'user is not signed in'
      include_context 'request is not xhr'
      before do
        allow(request).to receive(:fullpath).and_return('fullpath')
        allow(controller).to receive(:sign_in_path).with(anything).and_return('sign_in_path')
      end
      it do
        expect(controller).to receive(:redirect_to).with(any_args)
        subject
      end
    end
  end

  describe '#authenticate_admin!' do
    shared_context 'user is admin' do
      before { user.update(uid: User::ADMIN_UID) }
    end

    shared_context 'user is not admin' do
      before { user.update(uid: User::ADMIN_UID + 1) }
    end

    subject { controller.authenticate_admin! }

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it do
        expect(controller).to receive(:head).with(:forbidden)
        subject
      end
    end

    context 'user is signed in but is not admin' do
      include_context 'user is signed in'
      include_context 'user is not admin'
      it do
        expect(controller).to receive(:head).with(:forbidden)
        subject
      end
    end

    context 'user is signed in and is admin' do
      include_context 'user is signed in'
      include_context 'user is admin'
      it { is_expected.to be_nil }
    end
  end

  describe '#twitter_user_persisted?' do
    subject { controller.twitter_user_persisted?(1) }
    before { allow(TwitterUser).to receive_message_chain(:with_delay, :exists?).with(uid: 1).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#twitter_db_user_persisted?' do
    let(:user) { create(:user) }
    subject { controller.twitter_db_user_persisted?(user.uid) }

    it do
      expect(controller).to receive(:update_twitter_db_user).with(user.uid)
      expect(TwitterDB::User).to receive(:exists?).with(uid: user.uid).and_return('result')
      is_expected.to eq('result')
    end
  end

  describe '#validate_api_authorization!' do
    subject { controller.validate_api_authorization! }

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_truthy }
    end

    context 'user is signed in and authorized' do
      include_context 'user is signed in'
      include_context 'user is authorized'
      it { is_expected.to be_truthy }
    end

    context 'user is signed in and not authorized' do
      include_context 'user is signed in'
      include_context 'user is not authorized'
      before { allow(controller).to receive(:error_pages_api_not_authorized_path).with(anything).and_return('path') }
      it do
        expect(controller).to receive(:redirect_to).with('path')
        is_expected.to be_falsey
      end
    end
  end

  describe '#validate_dm_permission!' do
    shared_context 'user has proper permission' do
      before { allow(user).to receive(:enough_permission_level?).and_return(true) }
    end

    shared_context "user doesn't have proper permission" do
      before { allow(user).to receive(:enough_permission_level?).and_return(false) }
    end

    subject { controller.validate_dm_permission! }

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_truthy }
    end

    context 'user is signed in and has proper permission' do
      include_context 'user is signed in'
      include_context 'user has proper permission'
      it { is_expected.to be_truthy }
    end

    context "user is signed in and doesn't have proper permission" do
      include_context 'user is signed in'
      include_context "user doesn't have proper permission"
      before { allow(controller).to receive(:redirect_to).with(instance_of(String)) }
      it { is_expected.to be_falsey }
    end
  end

  describe '#valid_uid?' do
    subject { controller.valid_uid?(uid) }

    [123].each do |uid|
      context "uid is #{uid}" do
        let(:uid) { uid }
        it { is_expected.to be_truthy }
      end
    end

    ['aaa', '$123', '', nil].each do |uid|
      context "uid is #{uid}" do
        let(:uid) { uid }
        it do
          expect(controller).to receive(:respond_with_error).with(:bad_request, instance_of(String))
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#valid_screen_name?' do
    subject { controller.valid_screen_name?(name) }

    ['screen_name'].each do |name|
      context "screen_name is #{name}" do
        let(:name) { name }
        it { is_expected.to be_truthy }
      end
    end

    ['$aaa', '', nil].each do |name|
      context "screen_name is #{name}" do
        let(:name) { name }
        it do
          expect(controller).to receive(:respond_with_error).with(:bad_request, instance_of(String))
          is_expected.to be_falsey
        end
      end
    end
  end
end
