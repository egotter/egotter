require 'rails_helper'

RSpec.describe Api::V1::Base, type: :controller do
  controller Api::V1::Base do
    def summary_uids
    end

    def list_users
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
