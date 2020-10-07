require 'rails_helper'

describe ValidationConcern, type: :controller do
  controller ApplicationController do
    include ValidationConcern
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

  describe '#twitter_user_persisted?' do
    subject { controller.twitter_user_persisted?(1) }
    before { allow(TwitterUser).to receive_message_chain(:with_delay, :exists?).with(uid: 1).and_return(true) }
    it { is_expected.to be_truthy }
  end

  describe '#twitter_db_user_persisted?' do
    subject { controller.twitter_db_user_persisted?(1) }
    before do
      allow(TwitterDB::User).to receive(:exists?).with(uid: 1).and_return(found)
      allow(controller).to receive(:from_crawler?).and_return(false)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow(controller).to receive(:current_user_id).and_return(1)
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
    let(:screen_name) { 'screen_name' }
    subject { controller.not_found_screen_name?(screen_name) }
    before { allow(NotFoundUser).to receive(:exists?).with(screen_name: screen_name).and_return(found) }

    context 'screen_name is found' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not found' do
      let(:found) { true }
      before { allow(controller).to receive(:profile_path).with(anything).and_return('path') }
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
      allow(SearchRequestValidator).to receive_message_chain(:new, :not_found_user?).
          with(anything).with(screen_name).and_return(found)
    end

    context 'screen_name is found' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not found' do
      let(:found) { true }
      before { allow(controller).to receive(:profile_path).with(anything).and_return('path') }
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
      before { allow(controller).to receive(:profile_path).with(anything).and_return('path') }
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
      allow(SearchRequestValidator).to receive_message_chain(:new, :forbidden_user?).
          with(anything).with(screen_name).and_return(found)
    end

    context 'screen_name is forbidden' do
      let(:found) { false }
      it { is_expected.to be_falsey }
    end

    context 'screen_name is not forbidden' do
      let(:found) { true }
      before { allow(controller).to receive(:profile_path).with(anything).and_return('path') }
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
            allow(controller).to receive(:profile_path).with(any_args).and_return('protected_path')
          end
          it do
            expect(controller).to receive(:redirect_to).with('protected_path')
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
        allow(controller).to receive(:profile_path).with(any_args).and_return('blocked_path')
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
        expect(SearchRequestValidator).to receive_message_chain(:new, :user_requested_self_search_by_uid?).
            with(user).with(uid).and_return('result')
        is_expected.to eq('result')
      end
    end

    context 'user is not signed in' do
      include_context 'user is not signed in'
      it { is_expected.to be_falsey }
    end
  end
end
