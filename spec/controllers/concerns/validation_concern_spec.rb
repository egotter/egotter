require 'rails_helper'

describe Concerns::ValidationConcern, type: :controller do
  controller ApplicationController do
    include Concerns::ValidationConcern
  end

  describe '#require_login!' do
    subject { controller.require_login! }

    context 'With signing in' do
      before { allow(controller).to receive(:user_signed_in?).with(no_args).and_return(true) }
      it do
        expect(controller).to_not receive(:respond_with_error)
        subject
      end
    end

    context 'Without signing in' do
      before { allow(controller).to receive(:user_signed_in?).with(no_args).and_return(false) }
      it do
        expect(controller).to receive(:respond_with_error)
        subject
      end
    end
  end

  describe '#require_admin!' do
    let(:user) { create(:user, uid: User::ADMIN_UID) }
    subject { controller.require_admin! }

    context 'With signing in' do
      before do
        allow(controller).to receive(:user_signed_in?).with(no_args).and_return(true)
        allow(controller).to receive(:current_user).with(no_args).and_return(user)
      end
      it do
        expect(controller).to_not receive(:respond_with_error)
        subject
      end
    end

    context 'Without signing in' do
      before { allow(controller).to receive(:user_signed_in?).with(no_args).and_return(false) }
      it do
        expect(controller).to receive(:respond_with_error)
        subject
      end
    end
  end

  describe '#valid_uid?' do
    let(:uid) { 123 }

    it do
      expect(controller).to_not receive(:respond_with_error)
      expect(controller.valid_uid?(uid)).to be_truthy
    end

    context 'uid is aaa' do
      let(:uid) { 'aaa' }
      it do
        expect(controller).to receive(:respond_with_error)
        expect(controller.valid_uid?(uid)).to be_falsey
      end
    end

    context 'uid is ""' do
      let(:uid) { '' }
      it do
        expect(controller).to receive(:respond_with_error)
        expect(controller.valid_uid?(uid)).to be_falsey
      end
    end

    context 'uid is nil' do
      let(:uid) { nil }
      it do
        expect(controller).to receive(:respond_with_error)
        expect(controller.valid_uid?(uid)).to be_falsey
      end
    end
  end

  describe '#valid_screen_name?' do
    let(:screen_name) { 'screen_name' }

    it do
      expect(controller).to_not receive(:respond_with_error)
      expect(controller.valid_screen_name?(screen_name)).to be_truthy
    end

    context 'screen_name is $aaa' do
      let(:screen_name) { '$aaa' }
      it do
        expect(controller).to receive(:respond_with_error)
        expect(controller.valid_screen_name?(screen_name)).to be_falsey
      end
    end

    context 'screen_name is ""' do
      let(:screen_name) { '' }
      it do
        expect(controller).to receive(:respond_with_error)
        expect(controller.valid_screen_name?(screen_name)).to be_falsey
      end
    end

    context 'screen_name is nil' do
      let(:screen_name) { nil }
      it do
        expect(controller).to receive(:respond_with_error)
        expect(controller.valid_screen_name?(screen_name)).to be_falsey
      end
    end
  end
end
