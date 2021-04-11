require 'rails_helper'

RSpec.describe TimelinesController, type: :controller do
  describe 'GET #show' do
    let(:twitter_user) { build(:twitter_user, with_relations: false) }
    let(:screen_name) { twitter_user.screen_name }
    subject { get :show, params: {screen_name: screen_name} }

    it 'receives all before_action callbacks' do
      expect(controller).to receive(:valid_screen_name?)
      expect(controller).to receive(:not_found_screen_name?)
      expect(controller).to receive(:forbidden_screen_name?)
      expect(controller).to receive(:search_request_cache_exists?).with(screen_name)
      expect(controller).to receive(:current_user_search_for_yourself?).with(screen_name)
      expect(controller).to receive(:not_found_user?).with(screen_name).and_return(false)
      expect(controller).to receive(:forbidden_user?).with(screen_name).and_return(false)
      expect(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
      expect(controller).to receive(:private_mode_specified?).with(twitter_user)
      expect(controller).to receive(:search_limitation_soft_limited?).with(twitter_user)
      expect(controller).to receive(:protected_search?).with(twitter_user).and_return(false)
      expect(controller).to receive(:blocked_search?).with(twitter_user).and_return(false)
      expect(controller).to receive(:twitter_user_persisted?).with(twitter_user.uid)
      expect(controller).to receive(:twitter_db_user_persisted?).with(twitter_user.uid)
      expect(controller).to receive(:too_many_searches?).with(twitter_user).and_return(false)
      expect(controller).to receive(:too_many_requests?).with(twitter_user).and_return(false)
      expect(controller).to receive(:set_new_screen_name_if_changed)
      subject
    end

    context 'current_user_search_for_yourself? returns true' do
      before do
        allow(controller).to receive(:current_user_search_for_yourself?).with(screen_name).and_return(true)
      end

      it do
        expect(controller).to receive(:valid_screen_name?)
        expect(controller).to receive(:not_found_screen_name?)
        expect(controller).to receive(:forbidden_screen_name?)
        expect(controller).to receive(:search_request_cache_exists?).with(screen_name)
        # current_user_search_for_yourself? is called
        expect(controller).not_to receive(:not_found_user?).with(screen_name)
        expect(controller).not_to receive(:forbidden_user?).with(screen_name)
        expect(controller).to receive(:build_twitter_user_by).with(screen_name: screen_name).and_return(twitter_user)
        expect(controller).to receive(:private_mode_specified?).with(twitter_user)
        expect(controller).to receive(:search_limitation_soft_limited?).with(twitter_user)
        expect(controller).not_to receive(:protected_search?)
        expect(controller).not_to receive(:blocked_search?)
        expect(controller).to receive(:twitter_user_persisted?).with(twitter_user.uid)
        expect(controller).to receive(:twitter_db_user_persisted?).with(twitter_user.uid)
        expect(controller).to receive(:too_many_searches?).with(twitter_user).and_return(false)
        expect(controller).to receive(:too_many_requests?).with(twitter_user).and_return(false)
        expect(controller).to receive(:set_new_screen_name_if_changed)
        subject
      end
    end
  end
end
