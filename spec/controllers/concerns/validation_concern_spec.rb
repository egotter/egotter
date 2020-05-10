require 'rails_helper'

describe Concerns::ValidationConcern, type: :controller do
  controller ApplicationController do
    include Concerns::ValidationConcern
  end

  let(:user) { create(:user) }

  shared_context 'user is signed in' do
    before do
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end
  end

  shared_context 'user is not signed in' do
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

  describe '#signed_in_user_authorized?' do
    subject { controller.signed_in_user_authorized? }

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
      before do
        allow(controller).to receive(:signed_in_user_not_authorized_message).and_return('message')
      end
      it do
        expect(controller).to receive(:respond_with_error).with(:unauthorized, 'message')
        is_expected.to be_falsey
      end
    end
  end

  describe '#enough_permission_level?' do
    shared_context 'user has proper permission' do
      before { allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(true) }
    end

    shared_context "user doesn't have proper permission" do
      before { allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(false) }
    end

    subject { controller.enough_permission_level? }

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
      it do
        expect(controller).to receive(:respond_with_error).with(:unauthorized, instance_of(String))
        is_expected.to be_falsey
      end
    end
  end

  describe '#not_found_screen_name?' do
    shared_context 'screen_name is found' do
      before do
        allow(NotFoundUser).to receive(:exists?).with(anything).and_return(false)
        allow(controller).to receive(:not_found_user?).with(screen_name).and_return(false)
      end
    end

    shared_context 'screen_name is not found' do
      before { allow(NotFoundUser).to receive(:exists?).with(anything).and_return(true) }
    end

    let(:screen_name) { 'screen_name' }
    subject { controller.not_found_screen_name? }

    before do
      allow(controller.params).to receive(:[]).with(:screen_name).and_return(screen_name)
    end

    context 'screen_name is found' do
      include_context 'screen_name is found'
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not found' do
      include_context 'screen_name is not found'
      before do
        allow(controller).to receive(:not_found_path).with(anything).and_return('not_found_path')
      end
      it do
        expect(controller).to receive(:redirect_to).with('not_found_path')
        is_expected.to be_truthy
      end
    end
  end

  describe '#forbidden_screen_name?' do
    shared_context 'screen_name is forbidden' do
      before { allow(ForbiddenUser).to receive(:exists?).with(anything).and_return(true) }
    end

    shared_context 'screen_name is not forbidden' do
      before do
        allow(ForbiddenUser).to receive(:exists?).with(anything).and_return(false)
        allow(controller).to receive(:forbidden_user?).with(screen_name).and_return(false)
      end
    end

    let(:screen_name) { 'screen_name' }
    subject { controller.forbidden_screen_name? }

    before do
      allow(controller.params).to receive(:[]).with(:screen_name).and_return(screen_name)
    end

    context 'screen_name is forbidden' do
      include_context 'screen_name is forbidden'
      before do
        allow(controller).to receive(:forbidden_path).with(anything).and_return('forbidden_path')
      end
      it do
        expect(controller).to receive(:redirect_to).with('forbidden_path')
        is_expected.to be_truthy
      end
    end

    context 'screen_name is not forbidden' do
      include_context 'screen_name is not forbidden'
      it { is_expected.to be_falsey }
    end
  end

  describe '#protected_search?' do
    shared_context 'protected_user? returns true' do
      before { allow(controller).to receive(:protected_user?).with(anything).and_return(true) }
    end

    shared_context 'protected_user? returns false' do
      before { allow(controller).to receive(:protected_user?).with(anything).and_return(false) }
    end

    shared_context 'protected_user? raises an error' do
      before { allow(controller).to receive(:protected_user?).with(anything).and_raise('error') }
    end

    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    subject { controller.protected_search?(twitter_user) }

    context 'protected_user? returns true' do
      include_context 'protected_user? returns true'
      before do
        allow(controller).to receive(:protected_path).with(anything).and_return('protected_path')
      end
      it do
        expect(controller).to receive(:redirect_to).with('protected_path')
        is_expected.to be_truthy
      end
    end

    context 'protected_user? returns false' do
      include_context 'protected_user? returns false'
      it { is_expected.to be_falsey }
    end

    context 'protected_user? raises an error' do
      include_context 'protected_user? raises an error'
      before do
        allow(controller).to receive(:twitter_exception_messages).with(any_args).and_return('message')
      end
      it do
        expect(controller).to receive(:respond_with_error).with(:bad_request, instance_of(String))
        is_expected.to be_falsey
      end
    end
  end

  describe '#protected_user?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.protected_user?(screen_name) }

    context 'user is signed in' do
      include_context 'user is signed in'
      it do
        expect(SearchRequestValidator).to receive_message_chain(:new, :protected_user?).
            with(user).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it do
        expect(SearchRequestValidator).to receive_message_chain(:new, :protected_user?).
            with(nil).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end
  end

  describe '#blocked_search?' do
    shared_context 'blocked_user? returns true' do
      before { allow(controller).to receive(:blocked_user?).with(anything).and_return(true) }
    end

    shared_context 'blocked_user? returns false' do
      before { allow(controller).to receive(:blocked_user?).with(anything).and_return(false) }
    end

    shared_context 'blocked_user? raises an error' do
      before { allow(controller).to receive(:blocked_user?).with(anything).and_raise('error') }
    end

    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    subject { controller.blocked_search?(twitter_user) }

    context 'blocked_user? returns true' do
      include_context 'blocked_user? returns true'
      before do
        allow(controller).to receive(:blocked_path).with(anything).and_return('blocked_path')
      end
      it do
        expect(controller).to receive(:redirect_to).with('blocked_path')
        is_expected.to be_truthy
      end
    end

    context 'blocked_user? returns false' do
      include_context 'blocked_user? returns false'
      it { is_expected.to be_falsey }
    end

    context 'blocked_user? raises an error' do
      include_context 'blocked_user? raises an error'
      before do
        allow(controller).to receive(:twitter_exception_messages).with(any_args).and_return('message')
      end
      it do
        expect(controller).to receive(:respond_with_error).with(:bad_request, instance_of(String))
        is_expected.to be_falsey
      end
    end
  end

  describe '#blocked_user?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.blocked_user?(screen_name) }

    context 'user is signed in' do
      include_context 'user is signed in'
      it do
        expect(SearchRequestValidator).to receive_message_chain(:new, :blocked_user?).
            with(user).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it do
        expect(SearchRequestValidator).to receive_message_chain(:new, :blocked_user?).
            with(nil).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end
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
      before do
        allow(controller).to receive(:kick_out_error_path).with(any_args).and_return('kick_out_error_path')
      end
      it do
        expect(controller).to receive(:respond_with_error).with(:unauthorized, instance_of(String))
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
        expect(controller).to receive(:create_search_error_log).with(any_args)
        expect(controller).to receive(:render).with(hash_including(template: 'home/new', status: :unauthorized))
        subject
      end
    end
  end

  describe '#require_admin!' do
    shared_context 'user is admin' do
      before { user.update(uid: User::ADMIN_UID) }
    end

    shared_context 'user is not admin' do
      before { user.update(uid: User::ADMIN_UID + 1) }
    end

    subject { controller.require_admin! }

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it do
        expect(controller).to receive(:respond_with_error).with(:unauthorized, instance_of(String))
        subject
      end
    end

    context 'user is signed in but is not admin' do
      include_context 'user is signed in'
      include_context 'user is not admin'
      it do
        expect(controller).to receive(:respond_with_error).with(:unauthorized, instance_of(String))
        subject
      end
    end

    context 'user is signed in and is admin' do
      include_context 'user is signed in'
      include_context 'user is admin'
      it { is_expected.to be_nil }
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

  describe '#user_requested_self_search?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.user_requested_self_search? }

    before do
      allow(controller.params).to receive(:[]).with(:screen_name).and_return(screen_name)
    end

    context 'user is signed in' do
      include_context 'user is signed in'
      it do
        expect(SearchRequestValidator).to receive_message_chain(:new, :user_requested_self_search?).
            with(user).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_falsey }
    end
  end
end
