require 'rails_helper'

RSpec.describe HomeController, type: :controller do

  describe 'GET #new' do
    it do
      expect(controller).to receive(:create_search_log)
      get :new
    end

    it do
      expect(controller).not_to receive(:require_login!)
      get :new
    end
  end

  describe 'GET #start' do
    context 'from_crawler? == true' do
      before do
        allow(controller).to receive(:from_crawler?).with(no_args).and_return(true)
      end

      it do
        expect(controller).to receive(:require_login!)
        get :start
      end
    end

    context 'from_crawler? == false' do
      before do
        allow(controller).to receive(:from_crawler?).with(no_args).and_return(false)
      end

      it do
        expect(controller).to receive(:require_login!)
        get :start
      end
    end
  end
end
