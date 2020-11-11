require 'rails_helper'

describe BlockReportConcern, type: :controller do
  controller ApplicationController do
    include BlockReportConcern
  end

  let(:user) { create(:user) }

  before do
    allow(User).to receive(:find_by).with(uid: user.uid).and_return(user)
  end

  describe '#stop_block_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:stop_block_report_requested?, dm) }

    ['【ブロック通知 停止】', 'ブロック通知 停止', 'ブロック通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#restart_block_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:restart_block_report_requested?, dm.text) }

    ['【ブロック通知 再開】', 'ブロック通知 再開', 'ブロック通知再開'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#stop_block_report' do
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:stop_block_report, dm) }

    it do
      expect(CreateBlockReportStoppedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#restart_block_report' do
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:restart_block_report, dm) }

    it do
      expect(CreateBlockReportRestartedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
