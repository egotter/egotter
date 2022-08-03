require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  let(:user) { create(:user) }

  describe '#twitter' do
    let(:ahoy) { double('ahoy') }
    subject { controller.twitter }
    before do
      controller.instance_variable_set(:@user, user)
      allow(controller).to receive(:ahoy).and_return(ahoy)
      allow(controller).to receive(:detect_context).with(user).and_return(context)
      allow(controller).to receive(:after_callback_path).with(user, context).and_return('path')
    end

    context 'context is :create' do
      let(:context) { :create }
      it do
        expect(controller).to receive(:sign_in).with(user, event: :authentication)
        expect(ahoy).to receive(:authenticate).with(user)

        expect(ImportBlockingRelationshipsWorker).to receive(:perform_async).with(user.id)
        expect(ImportMutingRelationshipsWorker).to receive(:perform_async).with(user.id)
        expect(controller).to receive(:track_invitation_event)

        expect(controller).to receive(:track_registration_event).with(:create)
        expect(controller).to receive(:update_twitter_db_user).with(user.uid)
        expect(controller).to receive(:request_creating_twitter_user).with(user.uid)
        expect(controller).to receive(:follow_egotter).with(user)
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end

    context 'context is :update' do
      let(:context) { :update }
      it do
        expect(controller).to receive(:sign_in).with(user, event: :authentication)
        expect(ahoy).to receive(:authenticate).with(user)

        expect(UpdatePermissionLevelWorker).to receive(:perform_async).with(user.id)

        expect(controller).to receive(:track_registration_event).with(:update)
        expect(controller).to receive(:update_twitter_db_user).with(user.uid)
        expect(controller).to receive(:request_creating_twitter_user).with(user.uid)
        expect(controller).to receive(:follow_egotter).with(user)
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end
  end

  describe '#create_or_update_user' do
    subject { controller.send(:create_or_update_user) }
    before { allow(controller).to receive(:user_params).and_return('attrs') }
    it do
      expect(User).to receive(:update_or_create_with_token!).with('attrs').and_return('user')
      is_expected.to eq('user')
    end

    context 'exception is raised' do
      let(:error) { RuntimeError.new }
      before do
        allow(User).to receive(:update_or_create_with_token!).with(anything).and_raise(error)
        allow(controller).to receive(:error_pages_omniauth_failure_path).with(anything).and_return('path')
      end
      it do
        expect(controller).to receive(:redirect_to).with('path')
        subject
      end
    end

    describe '#detect_context' do
      it do
        expect(controller.send(:detect_context, user)).to eq(:create)
        travel_to 1.second.since do
          user.touch
          expect(controller.send(:detect_context, user)).to eq(:update)
        end
      end
    end

    describe '#track_registration_event' do
      let(:ahoy) { double('ahoy') }
      subject { controller.send(:track_registration_event, :create) }
      before do
        allow(controller).to receive(:ahoy).and_return(ahoy)
        allow(controller).to receive(:session).and_return(sign_in_via: 'via')
      end
      it do
        expect(ahoy).to receive(:track).with('Sign up', {via: 'via'})
        subject
      end
    end

    describe '#track_invitation_event' do
      let(:ahoy) { double('ahoy') }
      let(:click_id) { "invitation-#{user.uid}" }
      subject { controller.send(:track_invitation_event) }
      before do
        allow(controller).to receive(:ahoy).and_return(ahoy)
        allow(controller).to receive(:session).and_return(sign_in_click_id: click_id)
      end
      it do
        expect(ahoy).to receive(:track).with('Invitation', {click_id: click_id, inviter_uid: user.uid.to_s})
        subject
      end
    end
  end
end
