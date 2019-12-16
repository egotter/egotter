require 'rails_helper'

RSpec.describe CreatePromptReportLog, type: :model do
  describe '.recent_error_logs' do
    let(:user_id) { 1 }
    let(:request_id) { 2 }
    subject { described_class.recent_error_logs(user_id: user_id, request_id: request_id) }

    context 'user_id' do
      let!(:record1) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1) }
      let!(:record2) { create(:create_prompt_report_log, user_id: user_id + 1, request_id: request_id + 1) }
      it { is_expected.to match([record1]) }
    end

    context 'request_id' do
      let!(:record1) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1) }
      let!(:record2) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id) }
      it { is_expected.to match([record1]) }
    end

    context 'created_at' do
      let!(:record1) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1, created_at: 2.days.ago) }
      let!(:record2) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1, created_at: 1.hour.ago) }
      it { is_expected.to match([record2]) }
    end

    context 'error_class' do
      let!(:record1) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1, error_class: CreatePromptReportRequest::TooManyErrors) }
      let!(:record2) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1, error_class: RuntimeError) }
      it { is_expected.to match([record2]) }
    end

    context 'order' do
      let!(:record1) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1, created_at: 2.hours.ago) }
      let!(:record2) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1, created_at: 1.hour.ago) }
      it { is_expected.to match([record2, record1]) }
    end

    context 'limit' do
      let!(:record1) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1) }
      let!(:record2) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1) }
      let!(:record3) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1) }
      let!(:record4) { create(:create_prompt_report_log, user_id: user_id, request_id: request_id + 1) }
      it { is_expected.to satisfy { |records| records.size == 3 } }
    end
  end
end
