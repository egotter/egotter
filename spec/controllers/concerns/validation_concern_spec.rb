require 'rails_helper'

describe ValidationConcern, type: :controller do
  controller ApplicationController do
    include ValidationConcern
  end

  let(:user) { create(:user) }
  let(:client) { double('client') }
  let(:search_request_validator) { SearchRequestValidator.new(client, user) }

  before do
    allow(controller).to receive(:search_request_validator).and_return(search_request_validator)
  end

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
        expect(controller).to receive(:create_error_log).with(any_args)
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

  describe '#twitter_user_persisted?' do
    subject { controller.twitter_user_persisted?(1) }
    before { allow(TwitterUser).to receive_message_chain(:with_delay, :exists?).with(uid: 1).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#twitter_db_user_persisted?' do
    let(:user) { create(:user) }
    subject { controller.twitter_db_user_persisted?(user.uid) }
    before do
      allow(TwitterDB::User).to receive(:exists?).with(uid: user.uid).and_return(found)
      allow(controller).to receive(:from_crawler?).and_return(false)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'user is found' do
      let(:found) { true }
      it do
        expect(CreateTwitterDBUserWorker).to receive(:perform_async).with(any_args)
        is_expected.to be_truthy
      end
    end

    context 'user is not found' do
      let(:found) { false }
      it do
        expect(CreateHighPriorityTwitterDBUserWorker).to receive(:perform_async).with(any_args)
        is_expected.to be_falsey
      end
    end
  end

  describe '#current_user_authorized?' do
    subject { controller.current_user_authorized? }

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

  describe '#current_user_has_dm_permission?' do
    shared_context 'user has proper permission' do
      before { allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(true) }
    end

    shared_context "user doesn't have proper permission" do
      before { allow(user).to receive_message_chain(:notification_setting, :enough_permission_level?).and_return(false) }
    end

    subject { controller.current_user_has_dm_permission? }

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
      it do
        expect(controller).to receive(:create_error_log).with(:current_user_has_dm_permission?, 'permission_level_not_enough')
        is_expected.to be_falsey
      end
    end
  end

  describe '#not_found_screen_name?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.not_found_screen_name?(screen_name) }
    before { allow(NotFoundUser).to receive(:exists?).with(screen_name: screen_name).and_return(found) }

    context 'screen_name is found' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not found' do
      let(:found) { true }
      before { allow(controller).to receive(:error_pages_not_found_user_path).with(anything).and_return('path') }
      it do
        expect(controller).to receive(:redirect_to).with('path')
        is_expected.to be_truthy
      end
    end
  end

  describe '#not_found_user?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.not_found_user?(screen_name) }
    before do
      allow(search_request_validator).to receive(:not_found_user?).with(screen_name).and_return(found)
    end

    context 'screen_name is found' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not found' do
      let(:found) { true }
      before { allow(controller).to receive(:error_pages_not_found_user_path).with(anything).and_return('path') }
      it do
        expect(controller).to receive(:redirect_to).with('path')
        is_expected.to be_truthy
      end
    end
  end

  describe '#forbidden_screen_name?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.forbidden_screen_name?(screen_name) }
    before { allow(ForbiddenUser).to receive(:exists?).with(screen_name: screen_name).and_return(found) }

    context 'screen_name is forbidden' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not forbidden' do
      let(:found) { true }
      before { allow(controller).to receive(:error_pages_forbidden_user_path).with(anything).and_return('path') }
      it do
        expect(controller).to receive(:redirect_to).with('path')
        is_expected.to be_truthy
      end
    end
  end

  describe '#forbidden_user?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.forbidden_user?(screen_name) }
    before do
      allow(search_request_validator).to receive(:forbidden_user?).with(screen_name).and_return(found)
    end

    context 'screen_name is forbidden' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not forbidden' do
      let(:found) { true }
      before { allow(controller).to receive(:error_pages_forbidden_user_path).with(anything).and_return('path') }
      it do
        expect(controller).to receive(:redirect_to).with('path')
        is_expected.to be_truthy
      end
    end
  end

  describe '#protected_search?' do
    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    subject { controller.protected_search?(twitter_user) }

    context 'the user is not protected' do
      before { allow(controller).to receive(:protected_user?).with(anything).and_return(false) }
      it { is_expected.to be_falsey }
    end

    context 'the user is protected' do
      before { allow(controller).to receive(:protected_user?).with(anything).and_return(true) }

      context 'the user is searching yourself' do
        before { allow(controller).to receive(:search_yourself?).with(anything).and_return(true) }
        it { is_expected.to be_falsey }
      end

      context 'the user is not searching yourself' do
        before { allow(controller).to receive(:search_yourself?).with(anything).and_return(false) }

        context 'the timeline is readable' do
          before { allow(controller).to receive(:timeline_readable?).with(anything).and_return(true) }
          it { is_expected.to be_falsey }
        end

        context 'the timeline is not readable' do
          before do
            allow(controller).to receive(:timeline_readable?).with(anything).and_return(false)
            allow(controller).to receive(:error_pages_protected_user_path).with(any_args).and_return('path')
          end
          it do
            expect(controller).to receive(:redirect_to).with('path')
            is_expected.to be_truthy
          end
        end
      end
    end
  end

  describe '#protected_user?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.protected_user?(screen_name) }

    context 'user is signed in' do
      include_context 'user is signed in'
      it do
        expect(search_request_validator).to receive(:protected_user?).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it do
        expect(search_request_validator).to receive(:protected_user?).with(screen_name).and_return('result')
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
        allow(controller).to receive(:error_pages_you_have_blocked_path).with(any_args).and_return('path')
      end
      it do
        expect(controller).to receive(:redirect_to).with('path')
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
        expect(search_request_validator).to receive(:blocked_user?).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it do
        expect(search_request_validator).to receive(:blocked_user?).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
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

  describe '#current_user_search_for_yourself?' do
    let(:screen_name) { 'screen_name' }
    subject { controller.current_user_search_for_yourself?(screen_name) }

    before do
      allow(controller.params).to receive(:[]).with(:screen_name).and_return(screen_name)
    end

    context 'user is signed in' do
      include_context 'user is signed in'
      it do
        expect(search_request_validator).to receive(:search_for_yourself?).with(screen_name).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_falsey }
    end
  end

  describe '#user_requested_self_search_by_uid?' do
    # This value is passed from params, so it's String
    let(:uid) { '1' }
    subject { controller.user_requested_self_search_by_uid?(uid) }

    before do
      allow(controller.params).to receive(:[]).with(:uid).and_return(uid)
    end

    context 'user is signed in' do
      include_context 'user is signed in'
      it do
        expect(search_request_validator).to receive(:user_requested_self_search_by_uid?).with(uid).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_falsey }
    end
  end
end
