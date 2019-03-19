require 'rails_helper'

RSpec.describe TimelinesController, type: :helper do
  describe '#async_adsense_wrapper_id' do
    let(:position) { 'anything' }
    it 'returns same value for the same params' do
      id = helper.async_adsense_wrapper_id(position)
      expect(helper.async_adsense_wrapper_id(position)).to eq(id)
    end
  end
end
