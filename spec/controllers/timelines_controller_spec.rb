require 'rails_helper'

RSpec.describe TimelinesController, type: :controller do
  # Note: Not all validation methods need to be mocked because exceptions raised by Twitter API is rescued in SearchRequestValidator

  describe 'GET #show' do
    let(:screen_name) { 'screen_name' }
    subject { get :show, params: {screen_name: screen_name} }

    context 'With invalid screen_name' do
      let(:screen_name) { '$screen_name' }
      it { is_expected.to redirect_to root_path }
    end

    context 'With not_found screen_name' do
      before { NotFoundUser.create!(screen_name: screen_name) }
      it { is_expected.to redirect_to not_found_path(screen_name: screen_name) }
    end

    context 'With forbidden screen_name' do
      before { ForbiddenUser.create!(screen_name: screen_name) }
      it { is_expected.to redirect_to forbidden_path(screen_name: screen_name) }
    end

    context 'With blocked screen_name' do
      let(:twitter_user) { build(:twitter_user, screen_name: screen_name) }
      before do
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
        it { is_expected.to redirect_to blocked_path(screen_name: screen_name) }
      end

      context 'Without signed in' do
        before do
          allow(controller).to receive(:user_signed_in?).with(no_args).and_return(false)
          allow(controller).to receive(:protected_search?).with(twitter_user).and_return(false)
        end
        it do
          expect(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
          is_expected.to have_http_status(:success)
        end
      end
    end

    context 'With protected screen_name' do
      let(:twitter_user) { build(:twitter_user, screen_name: screen_name) }
      before do
        allow(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
        allow(controller).to receive(:protected_user?).with(screen_name).and_return(true)
      end

      it { is_expected.to redirect_to protected_path(screen_name: screen_name) }
    end
  end
end
