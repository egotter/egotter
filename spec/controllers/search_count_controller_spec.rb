require 'rails_helper'

RSpec.describe SearchCountController, type: :controller do
  describe 'GET #new' do
    subject { get :new }

    before do
      allow(UsageCount).to receive(:exists?).and_return(true)
      allow(UsageCount).to receive(:get).and_return(123)
    end

    it do
      is_expected.to have_http_status(:success)
      expect(JSON.parse(response.body)).to match('count' => 123)
    end

    context 'An exception is raised' do
      before { allow(UsageCount).to receive(:exists?).and_raise('Anything') }
      it do
        is_expected.to have_http_status(:success)
        expect(JSON.parse(response.body)).to match('count' => described_class::DEFAULT_COUNT)
      end
    end
  end
end
