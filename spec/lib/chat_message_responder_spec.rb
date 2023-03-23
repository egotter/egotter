require 'rails_helper'

describe ChatMessageResponder::Processor do
  let(:uid) { 1 }
  let(:text) { 'text' }
  let(:instance) { described_class.new(uid, text) }

  describe '#received?' do
    subject { instance.received? }

    ['雑談', '何してるの？'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    ['https://t.co/xxx123', '@user'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  shared_context 'it matches the regexp' do
    @allow_list.each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end

    @deny_list.each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#thanks_regexp' do
    subject { text.match?(instance.thanks_regexp) }
    @allow_list = ['ありがと', 'おつかれ']
    @deny_list = ['おつかれんこん']
    include_context 'it matches the regexp'
  end

  describe '#pretty_regexp' do
    subject { text.match?(instance.pretty_regexp) }
    @allow_list = ['アイコン可愛い', 'アイコン可愛くなった？']
    @deny_list = ['おつかれんこん']
    include_context 'it matches the regexp'
  end

  describe '#morning_regexp' do
    subject { text.match?(instance.morning_regexp) }
    @allow_list = ['おはよ', 'おはよう', 'おはようございます']
    @deny_list = ['こんにちは']
    include_context 'it matches the regexp'
  end

  describe '#afternoon_regexp' do
    subject { text.match?(instance.afternoon_regexp) }
    @allow_list = ['こんにちは', 'こんにちわ']
    @deny_list = ['こんばんは']
    include_context 'it matches the regexp'
  end

  describe '#evening_regexp' do
    subject { text.match?(instance.evening_regexp) }
    @allow_list = ['こんばんは',]
    @deny_list = ['おはよう']
    include_context 'it matches the regexp'
  end

  describe '#night_regexp' do
    subject { text.match?(instance.night_regexp) }
    @allow_list = ['おやすみ', 'おやすみなさい']
    @deny_list = ['おはよう']
    include_context 'it matches the regexp'
  end

  describe '#talk_regexp' do
    subject { text.match?(instance.talk_regexp) }
    @allow_list = ['えごったー']
    @deny_list = ['やっほー']
    include_context 'it matches the regexp'
  end

  describe '#yes_regexp' do
    subject { text.match?(instance.yes_regexp) }
    @allow_list = ['はい']
    @deny_list = ['はいはい']
    include_context 'it matches the regexp'
  end

  describe '#sorry_regexp' do
    subject { text.match?(instance.sorry_regexp) }
    @allow_list = ['すいません', 'すいませんでした', 'すみません', 'すみませんでした', 'ごめん', 'ごめんなさい']
    @deny_list = ['なんだい？']
    include_context 'it matches the regexp'
  end

  describe '#ok_regexp' do
    subject { text.match?(instance.ok_regexp) }
    @allow_list = ['おけ', 'おう']
    @deny_list = ['おけおけ']
    include_context 'it matches the regexp'
  end

  describe '#test_regexp' do
    subject { text.match?(instance.test_regexp) }
    @allow_list = ['DM送信テスト', 'DM届きました']
    @deny_list = ['DMテスト', 'DM届きましたよ']
    include_context 'it matches the regexp'
  end

  describe '#send_message' do
    subject { instance.send_message }

    [
        ['thanks', CreateThankYouMessageWorker],
        ['pretty', CreatePrettyIconMessageWorker],
        ['morning', CreateGreetingGoodMorningMessageWorker],
        ['afternoon', CreateGreetingGoodAfternoonMessageWorker],
        ['evening', CreateGreetingGoodEveningMessageWorker],
        ['night', CreateGreetingGoodNightMessageWorker],
        ['talk', CreateGreetingTalkMessageWorker],
        ['yes', CreateGreetingYesMessageWorker],
        ['sorry', CreateGreetingSorryMessageWorker],
        ['ok', CreateGreetingOkMessageWorker],
        ['test', CreateGreetingOkMessageWorker],
        ['chat', CreateChatMessageWorker],
    ].each do |name, worker_class|
      context "@#{name} is true" do
        before { instance.instance_variable_set(:"@#{name}", true) }
        it "#{worker_class} is expected to receive perform_async" do
          expect(worker_class).to receive(:perform_async).with(uid, text: 'text')
          subject
        end
      end
    end
  end
end
