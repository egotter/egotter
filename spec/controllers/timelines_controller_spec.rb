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
      let(:twitter_user) { build(:twitter_user) }
      before do
        ForbiddenUser.create!(screen_name: screen_name)
        allow(controller).to receive(:valid_screen_name?).with(no_args).and_return(true)
        allow(controller).to receive(:not_found_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:forbidden_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
      end

      context 'With signed in' do
        before do
          allow(controller).to receive(:user_signed_in?).with(no_args).and_return(true)
          allow(controller).to receive(:request_context_client).and_raise(RuntimeError, 'You have been blocked')
        end
        it do
          is_expected.to redirect_to root_path
        end
      end

      context 'Without signed in' do
        before do
          allow(controller).to receive(:user_signed_in?).with(no_args).and_return(false)
          allow(controller).to receive(:authorized_search?).with(twitter_user).and_return(true)
        end
        it do
          expect(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
          subject
        end
      end
    end

    context 'With not authorized screen_name' do
      let(:twitter_user) { build(:twitter_user) }
      before do
        ForbiddenUser.create!(screen_name: screen_name)
        allow(controller).to receive(:valid_screen_name?).with(no_args).and_return(true)
        allow(controller).to receive(:not_found_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:forbidden_screen_name?).with(no_args).and_return(false)
        allow(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
        allow(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
      end

      context 'twitter_user.suspended_account? returns true' do
        before { allow(twitter_user).to receive(:suspended_account?).with(no_args).and_return(true) }
        it do
          is_expected.to redirect_to root_path
        end
      end

      context 'twitter_user.suspended_account? returns false' do
        before { allow(twitter_user).to receive(:suspended_account?).with(no_args).and_return(false) }

        context 'twitter_user.public_account? returns true' do
          before do
            allow(twitter_user).to receive(:public_account?).with(no_args).and_return(true)
          end
          it do
            expect(controller).to receive(:authorized_search?).with(twitter_user).and_return(true)
            subject
          end
        end

        context 'twitter_user.public_account? returns false' do
          before do
            allow(twitter_user).to receive(:public_account?).with(no_args).and_return(false)
          end

          context 'user_signed_in? && twitter_user.readable_by?(current_user)' do
            before do
              allow(controller).to receive(:user_signed_in?).with(no_args).and_return(true)
              allow(twitter_user).to receive(:readable_by?).with(anything).and_return(true)
            end
            it do
              expect(controller).to receive(:authorized_search?).with(twitter_user).and_return(true)
              subject
            end
          end

          context 'else' do
            before do
              allow(controller).to receive(:user_signed_in?).with(no_args).and_return(true)
              allow(twitter_user).to receive(:readable_by?).with(anything).and_return(false)
            end
            it do
              is_expected.to redirect_to root_path
            end
          end
        end
      end

    end
  end
end
