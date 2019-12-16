require 'rails_helper'

RSpec.describe SearchLog, type: :model do
  describe '#with_login?' do
    subject { SearchLog.new(user_id: user_id).with_login? }

    context 'user_id == 1' do
      let(:user_id) { 1 }
      it { is_expected.to be_truthy }
    end

    context 'user_id == 10' do
      let(:user_id) { 10 }
      it { is_expected.to be_truthy }
    end

    context 'user_id == -1' do
      let(:user_id) { -1 }
      it { is_expected.to be_falsey }
    end

    context 'user_id == "-1"' do
      let(:user_id) { '-1' }
      it { is_expected.to be_falsey }
    end
  end

  describe '#crawler?' do
    let(:log) { SearchLog.new(device_type: 'hello', session_id: '123abc') }
    context 'device_type != crawler' do
      it 'returns false' do
        expect(log.device_type.to_s).not_to eq('crawler')
        expect(log.crawler?).to be_falsey
      end
    end

    context 'device_type == crawler' do
      it 'returns true' do
        expect(log.tap { |l| l.assign_attributes(device_type: 'crawler') }.crawler?).to be_truthy
        expect(log.tap { |l| l.assign_attributes(device_type: :crawler) }.crawler?).to be_truthy
      end
    end

    context 'session_id != -1' do
      it 'returns false' do
        expect(log.session_id.to_s).not_to eq('-1')
        expect(log.crawler?).to be_falsey
      end
    end

    context 'session_id == -1' do
      it 'returns true' do
        expect(log.tap { |l| l.assign_attributes(session_id: -1) }.crawler?).to be_truthy
        expect(log.tap { |l| l.assign_attributes(session_id: '-1') }.crawler?).to be_truthy
      end
    end
  end
end
