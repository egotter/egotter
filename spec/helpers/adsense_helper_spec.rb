require 'rails_helper'

RSpec.describe AdsenseHelper, type: :helper do
  describe '#ad_ng_user?' do
    let(:user) { double('user', uid: 1, name: 'name', description: 'description', location: 'location') }
    subject { helper.ad_ng_user?(user) }

    it do
      expect(helper).to receive(:ad_ng_uid?).with(user.uid)
      expect(helper).to receive(:ad_ng_text?).with(user.name)
      expect(helper).to receive(:ad_ng_text?).with(user.description)
      expect(helper).to receive(:ad_ng_text?).with(user.location)
      is_expected.to be_falsey
    end
  end

  describe '#ad_ng_uid?' do
    subject { helper.ad_ng_uid?(uid) }

    [100].each do |value|
      context "uid is #{value.inspect}" do
        let(:uid) { value }
        it { is_expected.to be_falsey }
      end
    end

    described_class::AD_NG_UIDS.each do |value|
      context "uid is #{value.inspect}" do
        let(:uid) { value }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#ad_ng_text?' do
    subject { helper.ad_ng_text?(text) }

    [nil, '', 'Hello'].each do |value|
      context "text is #{value.inspect}" do
        let(:text) { value }
        it { is_expected.to be_falsey }
      end
    end

    ['オナニー です'].each do |value|
      context "text is #{value.inspect}" do
        let(:text) { value }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#async_adsense_wrapper_id' do
    let(:position) { 'anything' }
    it 'returns same value for the same params' do
      id = helper.async_adsense_wrapper_id(position)
      expect(helper.async_adsense_wrapper_id(position)).to eq(id)
    end
  end
end
