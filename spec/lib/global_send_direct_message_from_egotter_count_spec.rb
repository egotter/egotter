require 'rails_helper'

RSpec.describe GlobalSendDirectMessageFromEgotterCount, type: :model do
  let(:instance) { described_class.new }

  describe '#key' do
    subject { instance.key }
    it { is_expected.to eq("#{Rails.env}:GlobalSendDirectMessageFromEgotterCount:86400:any_ids") }
  end

  describe '#increment' do
    subject { instance.increment }
    it { expect { subject }.to change { instance.size }.by(1) }
  end
end
