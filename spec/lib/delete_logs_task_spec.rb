require 'rails_helper'

RSpec.describe DeleteLogsTask, type: :model do
  let(:year) { '2021' }
  let(:month) { '01' }
  let(:instance) { described_class.new(SearchLog, year, month) }

  describe '#start' do
    subject { instance.start }
    before { create(:search_log, created_at: '2021-01-10') }
    it { expect { subject }.to change { SearchLog.all.size }.by(-1) }
  end
end
