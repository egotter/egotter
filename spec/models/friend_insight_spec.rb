require 'rails_helper'

RSpec.describe FriendInsight, type: :model do
  let(:instance) { described_class.new }

  describe '#fresh?' do
    subject { instance.fresh? }
    it { is_expected.to be_falsey }
  end


  describe '.builder' do
    subject { described_class.builder(1) }
    it do
      expect(described_class::Builder).to receive(:new).with(1)
      subject
    end
  end
end

RSpec.describe FriendInsight::Builder, type: :model do
  let(:instance) { described_class.new(1) }

  describe '#build' do

  end

  describe '#calc_profiles_count' do
    let(:users) { [double('User', description: 'hello'), double('User', description: 'world')] }
    subject { instance.send(:calc_profiles_count, users) }
    it do
      expect(WordCloud).to receive_message_chain(:new, :count_words).with(no_args).with('hello world')
      subject
    end
  end

  describe '#calc_locations_count' do
    let(:users) { [double('User', location: 'hello'), double('User', location: 'world')] }
    subject { instance.send(:calc_locations_count, users) }
    it do
      expect(WordCloud).to receive_message_chain(:new, :count_words).with(no_args).with('HELLO WORLD')
      subject
    end
  end
end
