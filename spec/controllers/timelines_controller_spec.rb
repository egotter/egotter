require 'rails_helper'

RSpec.describe TimelinesController, type: :controller do

  describe 'GET #show' do
    let(:screen_name) { 'screen_name' }
    let(:invalid_screen_name) { '$screen_name' }
    subject { get :show, params: {screen_name: screen_name} }

    context 'With invalid screen_name' do
      it do
        get :show, params: {screen_name: invalid_screen_name}
        expect(response).to redirect_to root_path
      end
    end

    context 'With not_found screen_name' do
      before do
        NotFoundUser.create!(screen_name: screen_name)
        allow(controller).to receive(:valid_screen_name?).with(no_args).and_return(true)
      end
      it do
        is_expected.to redirect_to not_found_path(screen_name: screen_name)
      end
    end

    context 'With forbidden screen_name' do
      before do
        ForbiddenUser.create!(screen_name: screen_name)
        allow(controller).to receive(:valid_screen_name?).with(no_args).and_return(true)
        allow(controller).to receive(:not_found_screen_name?).with(no_args).and_return(false)
      end
      it do
        is_expected.to redirect_to forbidden_path(screen_name: screen_name)
      end
    end

    context 'With blocked screen_name' do
      let(:twitter_user) { build(:twitter_user, screen_name: screen_name) }
      before do
        allow(controller).to receive(:valid_screen_name?).with(no_args).and_return(true)
        allow(controller).to receive(:not_found_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:forbidden_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
      end

      context 'With signed in' do
        let(:user) { create(:user, authorized: true) }
        before do
          user.create_notification_setting!
          user.notification_setting.update!(permission_level: NotificationSetting::PROPER_PERMISSION)

          allow(controller).to receive(:user_signed_in?).with(no_args).and_return(true)
          allow(controller).to receive(:current_user).with(no_args).and_return(user)
          allow(controller).to receive(:blocked_user?).with(screen_name).and_return(true)
        end
        it do
          is_expected.to redirect_to blocked_path(screen_name: screen_name)
        end
      end

      context 'Without signed in' do
        before do
          allow(controller).to receive(:user_signed_in?).with(no_args).and_return(false)
          allow(controller).to receive(:protected_search?).with(twitter_user).and_return(false)
        end
        it do
          expect(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
          subject
        end
      end
    end

    context 'With protected screen_name' do
      let(:twitter_user) { build(:twitter_user, screen_name: screen_name) }
      before do
        allow(controller).to receive(:valid_screen_name?).with(no_args).and_return(true)
        allow(controller).to receive(:not_found_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:forbidden_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
        allow(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
        allow(controller).to receive(:protected_user?).with(screen_name).and_return(true)
      end

      it do
        is_expected.to redirect_to protected_path(screen_name: screen_name)
      end
    end
  end
end
