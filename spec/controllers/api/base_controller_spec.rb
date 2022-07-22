require 'rails_helper'

RSpec.describe Api::BaseController, type: :controller do
  controller Api::BaseController do
    def summary_uids
    end

    def list_uids
    end
  end

  describe 'GET #summary' do
    subject { controller.summary }
    it do
      expect(controller).to receive(:summary_uids).and_return([[], 0])
      expect(controller).to receive(:render).with(json: {name: 'base', count: 0, users: []})
      subject
    end
  end
end
