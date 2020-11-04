require 'rails_helper'

describe SearchReportConcern, type: :controller do
  controller ApplicationController do
    include SearchReportConcern
  end

  let(:user) { create(:user) }

  before do
    allow(User).to receive(:find_by).with(uid: user.uid).and_return(user)
  end

  describe '#stop_search_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:stop_search_report_requested?, dm) }

    ['【検索通知 停止】', '検索通知 停止', '検索通知停止'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#restart_search_report_requested?' do
    let(:dm) { double('dm', text: text) }
    subject { controller.send(:restart_search_report_requested?, dm) }

    ['【検索通知 再開】', '検索通知 再開', '検索通知再開'].each do |word|
      context "text is #{word}" do
        let(:text) { word }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#stop_search_report' do
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:stop_search_report, dm) }

    it do
      expect(CreateSearchReportStoppedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end

  describe '#restart_search_report' do
    let(:dm) { double('dm', sender_id: user.uid) }
    subject { controller.send(:restart_search_report, dm) }

    it do
      expect(CreateSearchReportRestartedMessageWorker).to receive(:perform_async).with(user.id)
      subject
    end
  end
end
