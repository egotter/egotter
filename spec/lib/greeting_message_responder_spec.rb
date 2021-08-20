require 'rails_helper'

describe GreetingMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['おはよう'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it do
          is_expected.to be_truthy
          expect(instance.instance_variable_get(:@morning)).to be_truthy
        end
      end
    end
  end

  describe '#morning_regexp' do
    subject { text.match?(instance.morning_regexp) }

    [
        'おはよ',
        'おはよう',
        'おはようございます',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#afternoon_regexp' do
    subject { text.match?(instance.afternoon_regexp) }

    [
        'こんにちは',
        'こんにちわ',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#evening_regexp' do
    subject { text.match?(instance.evening_regexp) }

    [
        'こんばんは',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#night_regexp' do
    subject { text.match?(instance.night_regexp) }

    [
        'おやすみ',
        'おやすみなさい',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#talk_regexp' do
    subject { text.match?(instance.talk_regexp) }

    [
        'えごったー',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#yes_regexp' do
    subject { text.match?(instance.yes_regexp) }

    [
        'はい',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    [
        'はいはい',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#sorry_regexp' do
    subject { text.match?(instance.sorry_regexp) }

    [
        'すいません',
        'すいませんでした',
        'ごめん',
        'ごめんなさい',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#ok_regexp' do
    subject { text.match?(instance.ok_regexp) }

    [
        'おけ',
        'おう',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    [
        'おけおけ',
    ].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#send_message' do
    let(:user) { create(:user, uid: uid) }
    subject { instance.send_message }
    before { instance.instance_variable_set(:@uid, 1) }

    context '@morning is true' do
      before { instance.instance_variable_set(:@morning, true) }
      it do
        expect(CreateGreetingGoodMorningMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@afternoon is true' do
      before { instance.instance_variable_set(:@afternoon, true) }
      it do
        expect(CreateGreetingGoodAfternoonMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@evening is true' do
      before { instance.instance_variable_set(:@evening, true) }
      it do
        expect(CreateGreetingGoodEveningMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@night is true' do
      before { instance.instance_variable_set(:@night, true) }
      it do
        expect(CreateGreetingGoodNightMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@talk is true' do
      before { instance.instance_variable_set(:@talk, true) }
      it do
        expect(CreateGreetingTalkMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@yes is true' do
      before { instance.instance_variable_set(:@yes, true) }
      it do
        expect(CreateGreetingYesMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@sorry is true' do
      before { instance.instance_variable_set(:@sorry, true) }
      it do
        expect(CreateGreetingSorryMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end

    context '@ok is true' do
      before { instance.instance_variable_set(:@ok, true) }
      it do
        expect(CreateGreetingOkMessageWorker).to receive(:perform_async).with(uid)
        subject
      end
    end
  end
end
